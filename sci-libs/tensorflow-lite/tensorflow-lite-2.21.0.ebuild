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

# TF Lite's CMake build uses FetchContent / ExternalProject at configure time
# to download several vendored dependencies (farmhash, fft2d, gemmlowp, ruy,
# cpuinfo, XNNPACK, pthreadpool, FP16, NEON_2_SSE, ml_dtypes) that are not
# available as system packages in Gentoo.  Until each is packaged
# independently, we must allow network access during the build.
RESTRICT+=" network-sandbox"

# System-level dependencies that TF Lite can find via find_package().
RDEPEND="
	dev-cpp/abseil-cpp:=
	dev-libs/flatbuffers:=
	dev-cpp/eigen:3
"
DEPEND="
	${RDEPEND}
	gpu? (
		virtual/opencl
		media-libs/mesa[egl(+)]
	)
"
BDEPEND="
	>=dev-build/cmake-3.16
	app-arch/unzip
"

# Upstream's build defaults to Release and C++20.
CMAKE_BUILD_TYPE="Release"

# Point cmake at the tflite subdirectory, not the top-level TF CMakeLists.
CMAKE_USE_DIR="${S}/tensorflow/lite"

src_prepare() {
	# Apply patches from files/ if any.
	cmake_src_prepare
}

src_configure() {
	# Ensure PIC for shared library consumers.
	append-flags -fPIC

	local mycmakeargs=(
		# Required: point TF Lite's CMakeLists at the TF source root.
		-DTENSORFLOW_SOURCE_DIR="${S}"

		# Activate the install() rules so cmake --install works.
		-DTFLITE_ENABLE_INSTALL=ON

		# Feature toggles.
		-DTFLITE_ENABLE_XNNPACK=$(usex xnnpack ON OFF)
		-DTFLITE_ENABLE_GPU=$(usex gpu ON OFF)
		-DTFLITE_ENABLE_RUY=$(usex ruy ON OFF)

		# Disable example binaries to speed up the build.
		-DTFLITE_ENABLE_LABEL_IMAGE=OFF
		-DTFLITE_ENABLE_BENCHMARK_MODEL=OFF

		# Tests.
		-DTFLITE_KERNEL_TEST=$(usex test ON OFF)

		# NNAPI is Android-only; always off on Linux.
		-DTFLITE_ENABLE_NNAPI=OFF

		# Use system abseil, eigen, flatbuffers.
		-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON

		# Prefer system flatbuffers if available.
		-DFLATBUFFERS_FLATC_EXECUTABLE="${BROOT}/usr/bin/flatc"
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
		-S "${S}/tensorflow/lite/c" \
		-B "${c_build}" || die "C API cmake configure failed"

	cmake --build "${c_build}" -j "$(makeopts_jobs)" || die "C API build failed"
}

src_test() {
	cmake_src_test
}

src_install() {
	# Install the main static library, headers, and CMake config files.
	cmake_src_install

	# Install the C API shared library.
	local c_build="${WORKDIR}/tflite_c_build"

	# The C API build produces libtensorflowlite_c.so (or similar).
	local clib
	for clib in \
		"${c_build}/libtensorflowlite_c.so" \
		"${c_build}/libtensorflowlite_c.dylib" \
	; do
		if [[ -f "${clib}" ]]; then
			dolib.so "${clib}"
		fi
	done

	# Install public C API headers that consumers need.
	# These are the officially documented public headers.
	local hdr
	for hdr in \
		c/c_api.h \
		c/c_api_experimental.h \
		c/c_api_types.h \
		c/common.h \
	; do
		if [[ -f "${S}/tensorflow/lite/${hdr}" ]]; then
			insinto "/usr/include/tensorflow/lite/$(dirname "${hdr}")"
			doins "${S}/tensorflow/lite/${hdr}"
		fi
	done

	# Also install private headers that the public C headers transitively include.
	local dir
	for dir in \
		core/c \
		core/async/c \
		core/async/interop/c \
	; do
		if [[ -d "${S}/tensorflow/lite/${dir}" ]]; then
			insinto "/usr/include/tensorflow/lite/${dir}"
			doins "${S}/tensorflow/lite/${dir}"/*.h 2>/dev/null
		fi
	done

	# Install the top-level builtin_ops header.
	if [[ -f "${S}/tensorflow/lite/core/builtin_ops.h" ]]; then
		insinto "/usr/include/tensorflow/lite/core"
		doins "${S}/tensorflow/lite/core/builtin_ops.h"
	fi

	einstalldocs
}

pkg_postinst() {
	elog "TensorFlow Lite ${PV} has been installed."
	elog ""
	elog "Installed components:"
	elog "  - Static library: libtensorflow-lite.a"
	elog "  - C shared library: libtensorflowlite_c.so"
	elog "  - Headers: /usr/include/tensorflow/lite/"
	elog "  - CMake config: tensorflow-liteConfig.cmake"
	elog ""
	elog "To use in a CMake project:"
	elog "  find_package(tensorflow-lite REQUIRED)"
	elog "  target_link_libraries(myapp tensorflow-lite)"
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
