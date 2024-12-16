# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

K3S_EXTRAVERSION="k3s1"

DESCRIPTION="Lightweight Kubernetes binary (k3s)"
HOMEPAGE="https://k3s.io/"

if [[ ${ARCH} == "aarch64" ]]; then
    SRC_URI="https://github.com/k3s-io/k3s/releases/download/${PV}/k3s-arm64 -> k3s"
else
    SRC_URI="https://github.com/k3s-io/k3s/releases/download/${PV}/k3s"
fi

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64 ~aarch64"
IUSE=""

RESTRICT="strip test"

DEPEND=""
RDEPEND=""

S=${WORKDIR}

src_install() {
    dobin "dist/artifacts/${PN}"
    systemd_dounit "${FILESDIR}/${PN}.service"
}


