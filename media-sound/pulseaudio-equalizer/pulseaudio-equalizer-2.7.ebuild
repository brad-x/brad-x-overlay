# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=6

inherit eutils

DESCRIPTION="Pulseaudio Equalizer"
HOMEPAGE="https://launchpad.net/~nilarimogard"
SRC_URI="http://ppa.launchpad.net/nilarimogard/webupd8/ubuntu/pool/main/p/pulseaudio-equalizer/pulseaudio-equalizer_2.7.0.2-5~webupd8~xenial0_all.deb"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE=""

DEPEND=""
RDEPEND="${DEPEND}"

S=${WORKDIR}/usr

src_unpack() {
	unpack ${A}
	tar Jxf ${WORKDIR}/data.tar.xz
}

#src_prepare() {
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-current-volume.patch
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-do-not-crash-on-missing-preset.patch
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-force-default-persistence-value.patch
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-pulse-path.patch
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-remove-preamp.patch
#	epatch ${FILESDIR}/pulseaudio-equalizer-2.7-window-icon.patch
#}

src_install() {
	exeinto /usr/bin
	doexe bin/pulseaudio-equalizer
	doexe bin/pulseaudio-equalizer-gtk
	insinto /usr/share/
	doins -r share/pulseaudio-equalizer
	insinto /usr/share/applications
	doins share/applications/pulseaudio-equalizer.desktop
}
