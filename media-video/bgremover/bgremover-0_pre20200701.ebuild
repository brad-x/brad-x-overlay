# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

DESCRIPTION="Video4Linux background remover using TensorFlow Lite and DeepLab"
HOMEPAGE="https://github.com/yath/bgremover"

# Snapshot of master branch, commit 95bf31f541ba03ca25021ad04acfa9158a608809
COMMIT="95bf31f541ba03ca25021ad04acfa9158a608809"
SRC_URI="https://github.com/yath/bgremover/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"

# The upstream DeepLab v3 model file. Downloaded separately so it can be
# installed to /usr/share/bgremover without network access during src_compile.
MODEL_URI="https://storage.googleapis.com/download.tensorflow.org/models/tflite/gpu/deeplabv3_257_mv_gpu.tflite"
SRC_URI+=" ${MODEL_URI} -> deeplabv3_257_mv_gpu.tflite"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE="opengl"

# Build dependencies:
#   cmake     - build system (via cmake eclass)
# Runtime/link dependencies:
#   tensorflow-lite - TFLite C/C++ API (inference engine)
#   opencv          - video capture, image processing, GUI preview
#   glog            - Google logging
#   gflags          - Google commandline flags
#   tbb             - Intel TBB for std::execution parallel policies
#   opengl/egl      - optional GPU delegate support
#   v4l2loopback    - kernel module for virtual webcam (PDEPEND, optional)
RDEPEND="
	sci-libs/tensorflow-lite
	media-libs/opencv:=[v4l]
	dev-cpp/glog
	dev-cpp/gflags
	dev-cpp/tbb
	opengl? (
		virtual/opengl
		media-libs/mesa[egl(+)]
	)
"
DEPEND="
	${RDEPEND}
	sys-kernel/linux-headers
"
BDEPEND="
	dev-build/cmake
"
# v4l2loopback is needed at runtime to create the virtual camera device,
# but the binary itself builds and runs without it.
PDEPEND="
	media-video/v4l2loopback
"

PATCHES=(
	"${FILESDIR}/${P}-system-deps.patch"
)

src_prepare() {
	# Remove bundled glog/gflags submodule directories; we use system copies.
	rm -rf glog gflags || die "Failed to remove bundled submodules"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DWITH_GL=$(usex opengl ON OFF)
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	# Install the TFLite model file.
	insinto /usr/share/bgremover
	doins "${DISTDIR}/deeplabv3_257_mv_gpu.tflite"

	# Create a wrapper script that sets up the working directory so the
	# binary can find the .tflite model file in $PWD.
	newbin - bgremover <<-'EOF'
	#!/bin/sh
	# Wrapper script for bgremover (bgr).
	# The bgr binary expects deeplabv3_257_mv_gpu.tflite in the current
	# working directory. This wrapper creates a temporary directory with a
	# symlink to the installed model and any user-provided backgrounds/.
	set -e

	tmpdir=$(mktemp -d /tmp/bgremover.XXXXXX)
	trap 'rm -rf "${tmpdir}"' EXIT

	ln -s /usr/share/bgremover/deeplabv3_257_mv_gpu.tflite "${tmpdir}/"

	# If the user has a backgrounds/ directory in CWD, link it in.
	if [ -d "${PWD}/backgrounds" ]; then
	    ln -s "${PWD}/backgrounds" "${tmpdir}/backgrounds"
	fi

	cd "${tmpdir}"
	exec /usr/bin/bgr "$@"
	EOF

	# Rename the actual binary to bgr (matching upstream build output)
	# since the wrapper is installed as 'bgremover'.
	# (cmake_src_install already installs it as 'bgr' per CMakeLists.txt)

	einstalldocs
}

pkg_postinst() {
	elog "bgremover requires the v4l2loopback kernel module to create a"
	elog "virtual webcam device. Load it with:"
	elog ""
	elog "  modprobe v4l2loopback max_buffers=5 exclusive_caps=1"
	elog ""
	elog "Run 'bgremover' (wrapper) or 'bgr' (raw binary) to start."
	elog "The raw 'bgr' binary expects deeplabv3_257_mv_gpu.tflite in the"
	elog "current working directory. The 'bgremover' wrapper handles this"
	elog "automatically."
	elog ""
	elog "Place custom background images in a backgrounds/ directory in your"
	elog "current working directory before launching bgremover."
	elog ""
	elog "Default: captures from /dev/video0, writes to /dev/video2."
	elog "Use --input_device_number and --output_device_path to change."
	if use opengl; then
		elog ""
		elog "OpenGL GPU delegate support is enabled. This can accelerate"
		elog "TFLite inference on supported hardware."
	fi
}
