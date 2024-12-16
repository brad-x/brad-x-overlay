# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-info systemd

K3S_EXTRAVERSION="k3s1"

DESCRIPTION="Lightweight Kubernetes binary (k3s)"
HOMEPAGE="https://k3s.io/"

SRC_URI="amd64? ( https://github.com/k3s-io/k3s/releases/download/v1.31.3+k3s1/k3s -> k3s-amd64 )
	arm64? ( https://github.com/k3s-io/k3s/releases/download/v1.31.3+k3s1/k3s-arm64 )"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~arm64"
IUSE=""

RESTRICT="strip test"

DEPEND=""
RDEPEND=""

S=${WORKDIR}

src_install() {
    doexe "${DISTDIR}/k3s-${ARCH}" /usr/bin/k3s
    systemd_dounit "${FILESDIR}/k3s.service"
}


