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

# TF Lite's CMake build downloads vendored deps at configure time.
RESTRICT+=" network-sandbox"

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

CMAKE_BUILD_TYPE="Release"
CMAKE_USE_DIR="${S}/tensorflow/lite"

src_configure() {
	append-flags -fPIC

	local mycmakeargs=(
		-DTENSORFLOW_SOURCE_DIR="${S}"
		-DTFLITE_ENABLE_INSTALL=ON
		-DTFLITE_ENABLE_XNNPACK=$(usex xnnpack ON OFF)
		-DTFLITE_ENABLE_GPU=$(usex gpu ON OFF)
		-DTFLITE_ENABLE_RUY=$(usex ruy ON OFF)
		-DTFLITE_ENABLE_LABEL_IMAGE=OFF
		-DTFLITE_ENABLE_BENCHMARK_MODEL=OFF
		-DTFLITE_KERNEL_TEST=$(usex test ON OFF)
		-DTFLITE_ENABLE_NNAPI=OFF
		-DCMAKE_FIND_PACKAGE_PREFER_CONFIG=ON
		-DFLATBUFFERS_FLATC_EXECUTABLE="${BROOT}/usr/bin/flatc"

		# Vendored deps have ancient cmake_minimum_required(); CMake >=3.30
		# rejects anything below 3.5.  Set the policy floor accordingly.
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5
		-Wno-dev
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	einfo "Building TF Lite C API shared library..."
	local c_build="${WORKDIR}/tflite_c_build"
	mkdir -p "${c_build}" || die

	# Attempt to extract version from the source tree.
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
		-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
		-Wno-dev \
		-S "${S}/tensorflow/lite/c" \
		-B "${c_build}" || die "C API cmake configure failed"

	cmake --build "${c_build}" -j "$(makeopts_jobs)" || die "C API build failed"
}

src_install() {
	cmake_src_install

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

	if [[ -f "${S}/tensorflow/lite/core/builtin_ops.h" ]]; then
		insinto "/usr/include/tensorflow/lite/core"
		doins "${S}/tensorflow/lite/core/builtin_ops.h"
	fi

	einstalldocs
}

pkg_postinst() {
	elog "TensorFlow Lite (live) has been installed."
	elog ""
	elog "To use in a CMake project:"
	elog "  find_package(tensorflow-lite REQUIRED)"
	elog "  target_link_libraries(myapp tensorflow-lite)"
	if use gpu; then
		elog ""
		elog "GPU delegate (OpenCL) is enabled."
	fi
}
