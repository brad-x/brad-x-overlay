# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-video/handbrake/handbrake-0.9.9.ebuild,v 1.3 2013/06/29 20:35:06 tomwij Exp $

EAPI="5"

PYTHON_COMPAT=( python2_{5,6,7} )

inherit autotools eutils gnome2-utils python-any-r1

if [[ ${PV} = *9999* ]]; then
	ESVN_REPO_URI="svn://svn.handbrake.fr/HandBrake/trunk"
	inherit subversion
	KEYWORDS=""
else
	SRC_URI="http://handbrake.fr/rotation.php?file=HandBrake-${PV}.tar.bz2 -> ${P}.tar.bz2"
	S="${WORKDIR}/HandBrake-${PV}"
	KEYWORDS="~amd64 ~x86"
fi

DESCRIPTION="Open-source, GPL-licensed, multiplatform, multithreaded video transcoder."
HOMEPAGE="http://handbrake.fr/"
LICENSE="GPL-2"

SLOT="0"
IUSE="gtk"

# Use either ffmpeg or gst-plugins/mpeg2dec for decoding MPEG-2.

RDEPEND="
	sys-libs/zlib
	gtk? (
		x11-libs/gtk+:3
		dev-libs/dbus-glib
		dev-libs/glib:2
		x11-libs/cairo
		x11-libs/gdk-pixbuf:2
		x11-libs/libnotify
		x11-libs/pango
		>=virtual/udev-171[gudev]
	)
	"

DEPEND="${RDEPEND}
	${PYTHON_DEPS}
	dev-lang/yasm
	dev-util/intltool
	sys-devel/automake"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_prepare() {
	# Fixup configure.ac with newer automake
	cd "${S}/gtk"
	sed -i \
		-e 's:AM_CONFIG_HEADER:AC_CONFIG_HEADERS:g' \
		-e 's:AM_PROG_CC_STDC:AC_PROG_CC:g' \
		-e 's:am_cv_prog_cc_stdc:ac_cv_prog_cc_stdc:g' \
		configure.ac || die "Fixing up configure.ac failed"

	# Don't run autogen.sh
	sed -i '/autogen.sh/d' module.rules || die "Removing autogen.sh call failed"
	eautoreconf
}

src_configure() {
	./configure \
		--force \
		--prefix="${EPREFIX}/usr" \
		--disable-gtk-update-checks \
		${myconf} || die "Configure failed."
}

src_compile() {
	emake -C build

}

src_install() {
	emake -C build DESTDIR="${D}" install

	dodoc AUTHORS CREDITS NEWS THANKS TRANSLATIONS
}

pkg_postinst() {
	einfo "For the CLI version of HandBrake, you can use \`HandBrakeCLI\`."

	if use gtk ; then
		einfo ""
		einfo "For the GTK+ version of HandBrake, you can run \`ghb\`."
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	gnome2_icon_cache_update
}

pkg_postrm() {
	gnome2_icon_cache_update
}
