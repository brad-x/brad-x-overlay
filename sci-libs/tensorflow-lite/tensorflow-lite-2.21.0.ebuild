# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake flag-o-matic

DESCRIPTION="Lightweight ML inference framework (TensorFlow Lite / LiteRT)"
HOMEPAGE="
	https://www.tensorflow.org/lite
	https://github.com/tensorflow/tensorflow
"

MY_PV="${PV}"
SRC_URI="https://github.com/tensorflow/tensorflow/archive/v${MY_PV}.tar.gz -> tensorflow-${MY_PV}.tar.gz"
S="${WORKDIR}/tensorflow-${MY_PV}"

LICENSE="Apache-2.0"
SLOT="0/${PV}"
KEYWORDS="~amd64 ~arm64"
IUSE="gpu ruy test xnnpack"
RESTRICT="!test? ( test )"

# TF Lite's CMake build uses FetchContent at configure time to download and
# build ~15 vendored dependencies (abseil-cpp, eigen, flatbuffers, farmhash,
# fft2d, gemmlowp, ruy, cpuinfo, XNNPACK, pthreadpool, FP16, NEON_2_SSE,
# ml_dtypes, etc.).  These are all statically linked into libtensorflow-lite.a.
# Attempting to use system packages for a subset causes export-set and target
# name mismatches that break the build.  Until upstream supports full system
# dep usage, we let FetchContent manage everything.
RESTRICT+=" network-sandbox"

# No RDEPEND on vendored libraries — they are statically linked into the
# TF Lite archive.  Runtime deps are only needed for optional features.
RDEPEND="
	gpu? (
		virtual/opencl
		media-libs/mesa[egl(+)]
	)
"
DEPEND="${RDEPEND}"
BDEPEND="
	>=dev-build/cmake-3.16
	app-arch/unzip
"

# Upstream defaults to Release and C++20.
CMAKE_BUILD_TYPE="Release"

# Point cmake at the tflite subdirectory, not the top-level TF CMakeLists.
CMAKE_USE_DIR="${S}/tensorflow/lite"

src_prepare() {
	# Several vendored deps fetched at configure time (neon2sse, gemmlowp)
	# ship cmake_minimum_required(VERSION 2.8 ...) which CMake >=3.30
	# rejects outright.  Inject CMAKE_POLICY_VERSION_MINIMUM at the very
	# top of the TF Lite CMakeLists.txt so it is set BEFORE any
	# FetchContent/add_subdirectory pulls in those ancient files.
	sed -i '1i set(CMAKE_POLICY_VERSION_MINIMUM "3.5" CACHE STRING "Compat floor for vendored deps")' \
		"${S}/tensorflow/lite/CMakeLists.txt" || die "Failed to patch CMakeLists.txt"

	# Also patch the C API CMakeLists for the second build pass.
	sed -i '1i set(CMAKE_POLICY_VERSION_MINIMUM "3.5" CACHE STRING "Compat floor for vendored deps")' \
		"${S}/tensorflow/lite/c/CMakeLists.txt" || die "Failed to patch c/CMakeLists.txt"

	cmake_src_prepare
}

src_configure() {
	# Ensure PIC for shared library consumers.
	append-flags -fPIC

	local mycmakeargs=(
		# Required: point TF Lite's CMakeLists at the TF source root.
		-DTENSORFLOW_SOURCE_DIR="${S}"

		# Do NOT enable TFLITE_ENABLE_INSTALL.  It creates an
		# install(EXPORT) that references FetchContent targets (ruy,
		# flatbuffers, etc.) not present in the export set, causing a
		# fatal CMake error.  We do manual installation in src_install.
		-DTFLITE_ENABLE_INSTALL=OFF

		# Feature toggles.
		-DTFLITE_ENABLE_XNNPACK=$(usex xnnpack ON OFF)
		-DTFLITE_ENABLE_GPU=$(usex gpu ON OFF)
		-DTFLITE_ENABLE_RUY=$(usex ruy ON OFF)

		# Disable example binaries — avoids protobuf dependency and
		# speeds up the build.
		-DTFLITE_ENABLE_LABEL_IMAGE=OFF
		-DTFLITE_ENABLE_BENCHMARK_MODEL=OFF

		# Tests.
		-DTFLITE_KERNEL_TEST=$(usex test ON OFF)

		# NNAPI is Android-only; always off on Linux.
		-DTFLITE_ENABLE_NNAPI=OFF

		# Let TF Lite's own Find modules in tools/cmake/modules/ handle
		# ALL dependencies via FetchContent.  Do NOT set
		# CMAKE_FIND_PACKAGE_PREFER_CONFIG — it causes target name
		# mismatches (e.g. flatbuffers::flatbuffers not found).

		# Suppress noisy developer warnings from vendored FetchContent calls.
		-Wno-dev
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	# Additionally build the C API shared library.
	# TF Lite's C API has its own CMakeLists.txt under tensorflow/lite/c/.
	einfo "Building TF Lite C API shared library..."
	local c_build="${WORKDIR}/tflite_c_build"
	mkdir -p "${c_build}" || die

	# Extract TF_VERSION components for the C API build flags.
	local tf_version="${MY_PV}"
	local tf_major="${tf_version%%.*}"
	local tf_rest="${tf_version#*.}"
	local tf_minor="${tf_rest%%.*}"
	local tf_patch="${tf_rest#*.}"
	tf_patch="${tf_patch%%.*}"
	local tf_cxx_flags="-DTF_MAJOR_VERSION=${tf_major} -DTF_MINOR_VERSION=${tf_minor} -DTF_PATCH_VERSION=${tf_patch} -DTF_VERSION_SUFFIX=''"

	cmake \
		-DTENSORFLOW_SOURCE_DIR="${S}" \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_POSITION_INDEPENDENT_CODE=ON \
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr" \
		-DCMAKE_INSTALL_LIBDIR="$(get_libdir)" \
		-DCMAKE_C_FLAGS="${CFLAGS} ${tf_cxx_flags}" \
		-DCMAKE_CXX_FLAGS="${CXXFLAGS} ${tf_cxx_flags}" \
		-Wno-dev \
		-S "${S}/tensorflow/lite/c" \
		-B "${c_build}" || die "C API cmake configure failed"

	cmake --build "${c_build}" -j "$(makeopts_jobs)" || die "C API build failed"
}

src_test() {
	cmake_src_test
}

src_install() {
	# Since TFLITE_ENABLE_INSTALL=OFF, we do manual installation.
	local build_dir="${BUILD_DIR}"

	# --- Static library ---
	dolib.a "${build_dir}/libtensorflow-lite.a"

	# --- C API shared library ---
	local c_build="${WORKDIR}/tflite_c_build"
	local clib
	for clib in \
		"${c_build}/libtensorflowlite_c.so" \
		"${c_build}/libtensorflowlite_c.dylib" \
	; do
		if [[ -f "${clib}" ]]; then
			dolib.so "${clib}"
		fi
	done

	# --- Headers ---
	# Install the full tensorflow/lite header tree.  Consumers need headers
	# from core/, c/, delegates/, kernels/internal/, schema/, etc.
	cd "${S}" || die
	local header
	while IFS= read -r -d '' header; do
		local reldir
		reldir="$(dirname "${header}")"
		insinto "/usr/include/${reldir}"
		doins "${header}"
	done < <(find tensorflow/lite -name '*.h' \
		-not -path '*/test*' \
		-not -path '*/example*' \
		-not -path '*/benchmark*' \
		-not -path '*_test.h' \
		-not -path '*/java/*' \
		-not -path '*/objc/*' \
		-not -path '*/swift/*' \
		-not -path '*/python/*' \
		-not -path '*/ios/*' \
		-not -path '*/g3doc/*' \
		-print0)

	# Install vendored flatbuffers headers that the build downloaded,
	# since TF Lite public headers include them.
	if [[ -d "${build_dir}/flatbuffers/include/flatbuffers" ]]; then
		insinto /usr/include/flatbuffers
		doins "${build_dir}/flatbuffers/include/flatbuffers"/*.h
	fi

	# Install the generated schema_generated.h if present.
	local schema_gen="${build_dir}/schema_generated.h"
	if [[ -f "${schema_gen}" ]]; then
		insinto /usr/include/tensorflow/lite/schema
		doins "${schema_gen}"
	fi

	# --- pkg-config file ---
	cat > "${T}/tensorflow-lite.pc" <<-EOF || die
	prefix=${EPREFIX}/usr
	libdir=\${prefix}/$(get_libdir)
	includedir=\${prefix}/include

	Name: TensorFlow Lite
	Description: Lightweight ML inference framework
	Version: ${PV}
	Libs: -L\${libdir} -ltensorflow-lite
	Cflags: -I\${includedir}
	EOF
	insinto "/usr/$(get_libdir)/pkgconfig"
	doins "${T}/tensorflow-lite.pc"

	einstalldocs
}

pkg_postinst() {
	elog "TensorFlow Lite ${PV} has been installed."
	elog ""
	elog "Installed components:"
	elog "  - Static library: libtensorflow-lite.a"
	elog "  - C shared library: libtensorflowlite_c.so"
	elog "  - Headers: /usr/include/tensorflow/lite/"
	elog "  - pkg-config: tensorflow-lite.pc"
	elog ""
	elog "To link (pkg-config):"
	elog "  pkg-config --cflags --libs tensorflow-lite"
	elog ""
	elog "Or link the C API directly:"
	elog "  -ltensorflowlite_c"
	elog ""
	elog "NOTE: TF Lite is being succeeded by LiteRT. See:"
	elog "  https://github.com/google-ai-edge/LiteRT"
	if use gpu; then
		elog ""
		elog "GPU delegate (OpenCL) is enabled. Requires OpenCL 1.2+ at runtime."
	fi
}
