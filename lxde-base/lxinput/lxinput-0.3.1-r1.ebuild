# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/lxde-base/lxinput/lxinput-0.3.1.ebuild,v 1.2 2011/08/03 09:31:54 hwoarang Exp $

EAPI=4

inherit eutils

DESCRIPTION="LXDE keyboard and mouse configuration tool"
HOMEPAGE="http://lxde.sourceforge.net/"
SRC_URI="mirror://sourceforge/lxde/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 arm ppc x86"
IUSE="clip clip-deps"

RDEPEND="!clip-deps? ( dev-libs/glib:2 )
	clip? ( x11-apps/xset )
	x11-libs/gtk+:2"
DEPEND="${RDEPEND}
	sys-devel/gettext
	dev-util/pkgconfig
	>=dev-util/intltool-0.40.0"

src_prepare() {
	use clip && epatch "${FILESDIR}/${PN}-0.3.1-clip-config.patch"
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	dodoc AUTHORS README || die 'dodoc failed'

	if use clip; then
		exeinto "/usr/bin"
		doexe "${FILESDIR}/lxinput-restore"
	fi
}
