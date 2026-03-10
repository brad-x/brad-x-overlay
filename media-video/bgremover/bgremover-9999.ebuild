# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake git-r3

DESCRIPTION="Video4Linux background remover using TensorFlow Lite and DeepLab"
HOMEPAGE="https://github.com/yath/bgremover"

EGIT_REPO_URI="https://github.com/yath/bgremover.git"

# The upstream DeepLab v3 model file.
MODEL_URI="https://storage.googleapis.com/download.tensorflow.org/models/tflite/gpu/deeplabv3_257_mv_gpu.tflite"
SRC_URI="${MODEL_URI} -> deeplabv3_257_mv_gpu.tflite"

LICENSE="Apache-2.0"
SLOT="0"
IUSE="opengl"

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
PDEPEND="
	media-video/v4l2loopback
"

# Live ebuilds reuse the same patch; filename is stable across versions.
PATCHES=(
	"${FILESDIR}/bgremover-0_pre20200701-system-deps.patch"
)

src_prepare() {
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

	insinto /usr/share/bgremover
	doins "${DISTDIR}/deeplabv3_257_mv_gpu.tflite"

	newbin - bgremover <<-'EOF'
	#!/bin/sh
	set -e
	tmpdir=$(mktemp -d /tmp/bgremover.XXXXXX)
	trap 'rm -rf "${tmpdir}"' EXIT
	ln -s /usr/share/bgremover/deeplabv3_257_mv_gpu.tflite "${tmpdir}/"
	if [ -d "${PWD}/backgrounds" ]; then
	    ln -s "${PWD}/backgrounds" "${tmpdir}/backgrounds"
	fi
	cd "${tmpdir}"
	exec /usr/bin/bgr "$@"
	EOF

	einstalldocs
}

pkg_postinst() {
	elog "bgremover requires the v4l2loopback kernel module to create a"
	elog "virtual webcam device. Load it with:"
	elog ""
	elog "  modprobe v4l2loopback max_buffers=5 exclusive_caps=1"
	elog ""
	elog "Run 'bgremover' (wrapper) or 'bgr' (raw binary) to start."
	elog "Place custom backgrounds in a backgrounds/ dir in your CWD."
	if use opengl; then
		elog ""
		elog "OpenGL GPU delegate support is enabled."
	fi
}
