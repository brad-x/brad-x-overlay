# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit cmake

DESCRIPTION="Qt decoration plugin implementing Adwaita-like client-side decorations"
HOMEPAGE="https://github.com/FedoraQt/QAdwaitaDecorations"
SRC_URI="https://github.com/FedoraQt/${PN}/archive/${PV}/${P}.tar.gz"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~ppc64 x86"
IUSE="qt5 +qt6"
REQUIRED_USE="|| ( qt5 qt6 )"

DEPEND="
	qt5? (
		dev-qt/qtcore:5
		dev-qt/qtgui:5
		dev-qt/qtsvg:5
		dev-qt/qtwayland:5
		dev-qt/qtwidgets:5
	)
	qt6? (
		dev-qt/qtbase:6[gui,widgets]
		dev-qt/qtsvg:6
		dev-qt/qtwayland:6
	)
"
RDEPEND="${DEPEND}"

src_configure() {
	if use qt5; then
		BUILD_DIR="${WORKDIR}/${PN}_qt5"
		local mycmakeargs=(-DUSE_QT6=false -DHAS_QT6_SUPPORT=true)
		cmake_src_configure
	fi
	if use qt6; then
		BUILD_DIR="${WORKDIR}/${PN}_qt6"
		local mycmakeargs=(-DUSE_QT6=true)
		cmake_src_configure
	fi
}

src_compile() {
	local _d
	for _d in "${WORKDIR}"/${PN}_qt*; do
		cmake_src_compile -C "${_d}"
	done
}

src_install() {
	local _d
	for _d in "${WORKDIR}"/${PN}_qt*; do
		cmake_src_install -C "${_d}"
	done
}
