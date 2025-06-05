# Copyright 2025
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Terminal UI to manage Kubernetes clusters"
HOMEPAGE="https://github.com/derailed/k9s"
SRC_URI="
	amd64? ( https://github.com/derailed/k9s/releases/download/v0.50.6/k9s_Linux_amd64.tar.gz -> k9s-bin-0.50.6-amd64.tar.gz )
	arm64? ( https://github.com/derailed/k9s/releases/download/v0.50.6/k9s_Linux_arm64.tar.gz -> k9s-bin-0.50.6-arm64.tar.gz )
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

RESTRICT="mirror strip"

BDEPEND="app-arch/tar"

S="${WORKDIR}"

src_unpack() {
	local archive
	case ${ARCH} in
		amd64) archive="k9s-bin-0.50.6-amd64.tar.gz" ;;
		arm64) archive="k9s-bin-0.50.6-arm64.tar.gz" ;;
		*) die "Unsupported ARCH: ${ARCH}" ;;
	esac

	mkdir "${WORKDIR}/unpacked" || die
	tar -C "${WORKDIR}/unpacked" -xf "${DISTDIR}/${archive}" || die
}

src_install() {
	dobin "${WORKDIR}/unpacked/k9s" || die
}
