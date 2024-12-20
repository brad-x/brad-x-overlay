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
IUSE="+kubectl-symlink rootless"

RESTRICT="strip test"

DEPEND="
    app-misc/yq
    net-firewall/conntrack-tools
    rootless? ( app-containers/slirp4netns )
"
RDEPEND="kubectl-symlink? ( !sys-cluster/kubectl )"

S=${WORKDIR}

src_install() {
    exeinto /usr/bin
    doexe "${DISTDIR}/${A}"
	dosym "/usr/bin/k3s-${ARCH}" /usr/bin/k3s
    systemd_dounit "${FILESDIR}/k3s.service"

    use kubectl-symlink && dosym k3s /usr/bin/kubectl
    insinto /etc/logrotate.d
    newins "${FILESDIR}/k3s.logrotated" "${PN}"
}


