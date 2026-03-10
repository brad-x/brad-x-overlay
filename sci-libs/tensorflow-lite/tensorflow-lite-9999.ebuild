# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake flag-o-matic git-r3

DESCRIPTION="Lightweight ML inference framework (TensorFlow Lite / LiteRT)"
HOMEPAGE="
	https://www.tensorflow.org/lite
	https://github.com/tensorflow/tensorflow
"

EGIT_REPO_URI="https://github.com/tensorflow/tensorflow.git"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="gpu ruy test xnnpack"
RESTRICT="!test? ( test )"

# TF Lite's CMake build uses FetchContent to download vendored deps.
RESTRICT+=" network-sandbox"

RDEPEND="
	dev-libs/flatbuffers
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

CMAKE_BUILD_TYPE="Release"
CMAKE_USE_DIR="${S}/tensorflow/lite"

src_prepare() {
	sed -i '1i set(CMAKE_POLICY_VERSION_MINIMUM "3.5" CACHE STRING "Compat floor for vendored deps")' \
		"${S}/tensorflow/lite/CMakeLists.txt" || die
	sed -i '1i set(CMAKE_POLICY_VERSION_MINIMUM "3.5" CACHE STRING "Compat floor for vendored deps")' \
		"${S}/tensorflow/lite/c/CMakeLists.txt" || die

	cmake_src_prepare
}

src_configure() {
	append-flags -fPIC

	local mycmakeargs=(
		-DTENSORFLOW_SOURCE_DIR="${S}"
		-DTFLITE_ENABLE_INSTALL=OFF
		-DTFLITE_ENABLE_XNNPACK=$(usex xnnpack ON OFF)
		-DTFLITE_ENABLE_GPU=$(usex gpu ON OFF)
		-DTFLITE_ENABLE_RUY=$(usex ruy ON OFF)
		-DTFLITE_ENABLE_LABEL_IMAGE=OFF
		-DTFLITE_ENABLE_BENCHMARK_MODEL=OFF
		-DTFLITE_KERNEL_TEST=$(usex test ON OFF)
		-DTFLITE_ENABLE_NNAPI=OFF
		-Wno-dev
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	einfo "Main build artifacts in BUILD_DIR=${BUILD_DIR}:"
	find "${BUILD_DIR}" -maxdepth 2 \( -name '*.a' -o -name '*.so' \) \
		2>/dev/null | while read -r f; do einfo "  ${f}"; done

	einfo "Building TF Lite C API shared library..."
	local c_build="${WORKDIR}/tflite_c_build"
	mkdir -p "${c_build}" || die

	local tf_version
	tf_version=$(sed -n 's/.*TF_VERSION = "\([^"]*\)".*/\1/p' \
		"${S}/tensorflow/tf_version.bzl" 2>/dev/null)
	local tf_major="${tf_version%%.*}"
	local tf_rest="${tf_version#*.}"
	local tf_minor="${tf_rest%%.*}"
	local tf_patch="${tf_rest#*.}"
	tf_patch="${tf_patch%%.*}"
	local tf_cxx_flags=""
	if [[ -n "${tf_major}" ]]; then
		tf_cxx_flags="-DTF_MAJOR_VERSION=${tf_major} -DTF_MINOR_VERSION=${tf_minor} -DTF_PATCH_VERSION=${tf_patch} -DTF_VERSION_SUFFIX=''"
	fi

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

src_install() {
	local build_dir="${BUILD_DIR}"

	# --- Static library (search for it) ---
	local tflite_a
	tflite_a=$(find "${build_dir}" "${WORKDIR}" -maxdepth 3 \
		-name 'libtensorflow-lite.a' -print -quit 2>/dev/null)
	if [[ -z "${tflite_a}" ]]; then
		eerror "libtensorflow-lite.a not found.  BUILD_DIR contents:"
		find "${build_dir}" -maxdepth 2 -name '*.a' -o -name '*.so' 2>/dev/null | \
			while read -r f; do eerror "  ${f}"; done
		die "libtensorflow-lite.a not found in build tree"
	fi
	einfo "Found static library: ${tflite_a}"
	dolib.a "${tflite_a}"

	# --- C API shared library ---
	local c_build="${WORKDIR}/tflite_c_build"
	local clib
	clib=$(find "${c_build}" -maxdepth 3 \
		-name 'libtensorflowlite_c.so' -print -quit 2>/dev/null)
	if [[ -n "${clib}" ]]; then
		einfo "Found C API library: ${clib}"
		dolib.so "${clib}"
	else
		ewarn "libtensorflowlite_c.so not found — C API not installed."
	fi

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

	# Do NOT install vendored flatbuffers headers — they collide with
	# dev-libs/flatbuffers which is a runtime dependency for the headers.

	local schema_gen
	schema_gen=$(find "${build_dir}" -maxdepth 3 \
		-name 'schema_generated.h' -print -quit 2>/dev/null)
	if [[ -n "${schema_gen}" ]]; then
		insinto /usr/include/tensorflow/lite/schema
		doins "${schema_gen}"
	fi

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
	elog "TensorFlow Lite (live) has been installed."
	elog ""
	elog "To link: pkg-config --cflags --libs tensorflow-lite"
	elog "C API:   -ltensorflowlite_c"
	if use gpu; then
		elog ""
		elog "GPU delegate (OpenCL) is enabled."
	fi
}
