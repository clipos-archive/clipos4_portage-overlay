# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-auth/tcb/tcb-1.0.2.ebuild,v 1.1 2008/03/27 14:45:01 flameeyes Exp $

EAPI="2"

inherit eutils user multilib

DESCRIPTION="Libraries and tools implementing the tcb password shadowing scheme"
HOMEPAGE="http://www.openwall.com/tcb/"
SRC_URI="ftp://ftp.openwall.com/pub/projects/tcb/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ppc x86"
IUSE="clip clip-tcb clip-devstation"

DEPEND=">=sys-libs/pam-0.75"
RDEPEND="${DEPEND}"

pkg_setup() {
	for group in auth chkpwd shadow ; do
		enewgroup ${group}
	done

	mymakeopts="
		SLIBDIR=/$(get_libdir)
		LIBDIR=/usr/$(get_libdir)
		MANDIR=/usr/share/man
		DESTDIR='${D}'"
}

src_prepare() {
	use clip-tcb || epatch "${FILESDIR}"/${PN}-gentoo.patch
	use clip && epatch "${FILESDIR}"/${PN}-1.0.2-etc-core.patch
}

src_compile() {
	emake $mymakeopts || die "emake failed"
}

src_install() {
	emake $mymakeopts install || die "emake install failed"
	dodoc ChangeLog
	use clip-devstation && dodir "/etc/tcb"
}

pkg_postinst() {
	einfo "You must now run /sbin/tcb_convert to convert your shadow to tcb"
	einfo "To remove this you must first run /sbin/tcp_unconvert and then unmerge"
}
