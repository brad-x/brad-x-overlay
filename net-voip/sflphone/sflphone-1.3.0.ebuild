# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-voip/sflphone/sflphone-1.2.3.ebuild,v 1.1 2013/08/03 16:13:58 elvanor Exp $

EAPI=5

inherit autotools eutils kde4-base gnome2

DESCRIPTION="SFLphone is a robust standards-compliant enterprise softphone, for desktop and embedded systems."
HOMEPAGE="http://www.sflphone.org/"
SRC_URI="https://projects.savoirfairelinux.com/attachments/download/9198/${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="debug doxygen gnome gsm kde networkmanager opus pulseaudio speex static-libs"

CDEPEND="dev-cpp/commoncpp2
	dev-libs/dbus-c++
	dev-libs/expat
	dev-libs/ilbc-rfc3951
	dev-libs/libpcre
	dev-libs/libyaml
	dev-libs/openssl
	media-libs/alsa-lib
	media-libs/libsamplerate
	opus? ( media-libs/opus )
	pulseaudio? ( media-sound/pulseaudio )
	net-libs/ccrtp
	net-libs/libzrtpcpp
	sys-apps/dbus
	gnome? ( dev-libs/atk
		dev-libs/check
		gnome-base/libgnomeui
		gnome-base/orbit:2
		gnome-extra/evolution-data-server
		media-libs/fontconfig
		media-libs/freetype
		media-libs/libart_lgpl
		net-libs/libsoup:2.4
		net-libs/webkit-gtk:3
		x11-libs/cairo
		x11-libs/libICE
		x11-libs/libnotify
		x11-libs/libSM )
	gsm? ( media-sound/gsm )
	kde? ( kde-base/kdepimlibs
		kde-base/kdelibs )
	networkmanager? ( net-misc/networkmanager )
	speex? ( media-libs/speex )"

DEPEND="${CDEPEND}
		>=net-libs/pjsip-2.1
		>=dev-util/astyle-1.24
		doxygen? ( app-doc/doxygen )
		gnome? ( app-text/gnome-doc-utils )
		virtual/pkgconfig"

RDEPEND="${CDEPEND}"

REQUIRED_USE="|| ( gnome kde )"

src_prepare() {
	epatch "${FILESDIR}"/sflphone-externalpjsip.patch
	cd "${S}/daemon"||die
	rm -rf libs/pjproject-2.1.0 || die
	eautoreconf

	if use kde; then
		S="${S}/kde"
		sed -i -e "s|\.\.|\.\./sflphone-1.3.0/kde|" ../kde/src/klib/kcfg_settings.kcfgc||die
		kde4-base_src_prepare
	fi
}

src_configure() {
	cd "${WORKDIR}/${P}/daemon"
	econf --disable-dependency-tracking $(use_with debug) $(use_with gsm) \
		$(use_with networkmanager) $(use_with speex) \
		$(use_enable static-libs static) $(use_enable doxygen) \
		$(use_with pulseaudio pulse) $(use_with opus)

	#if use gnome && ! use kde; then
	if use gnome; then
		cd "${WORKDIR}/${P}/gnome" ||die
		econf $(use_enable static-libs static)
	fi

	use kde && kde4-base_src_configure
}

src_compile() {
	cd "${WORKDIR}/${P}/daemon" ||die
	emake

	#if use gnome && ! use kde; then
	if use gnome; then
		cd ../gnome ||die
		emake
	fi
	use kde && kde4-base_src_compile
}

src_install() {
	if use gnome; then
		S="${WORKDIR}/${P}/gnome"
		gnome2_src_install
	fi

	use kde && kde4-base_src_install

	cd "${WORKDIR}/${P}/daemon" ||die
	emake -j1 DESTDIR="${D}" install
}

pkg_postinst() {
	elog
	elog "You need to restart dbus, if you want to access"
	elog "sflphoned through dbus."
	elog
	elog
	elog "If you use the command line client"
	elog "(https://projects.savoirfairelinux.com/repositories/browse/sflphone/tools/pysflphone)"
	elog "extract /usr/share/doc/${PF}/${PN}drc-sample to"
	elog "~/.config/${PN}/${PN}drc for example config."
	elog
	elog
	elog "For calls out of your browser have a look in sflphone-callto"
	elog "and sflphone-handler. You should consider to install"
	elog "the \"Telify\" Firefox addon. See"
	elog "https://projects.savoirfairelinux.com/repositories/browse/sflphone/tools"
	elog
	if use gnome; then
		gnome2_pkg_postinst
		elog
		elog "sflphone-client-gnome: To manage your contacts you need"
		elog "mail-client/evolution or access to an evolution-data-server"
		elog "connected backend."
		elog
	fi
}
