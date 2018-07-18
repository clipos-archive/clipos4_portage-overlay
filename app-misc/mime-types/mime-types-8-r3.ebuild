# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-misc/mime-types/mime-types-7.ebuild,v 1.11 2007/06/30 17:23:17 armin76 Exp $

EAPI=4

inherit eutils

DESCRIPTION="Provides /etc/mime.types file"
HOMEPAGE="http://www.gentoo.org/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd"
IUSE="clip"

DEPEND=""
RDEPEND=""

src_prepare() {
	use clip && epatch "${FILESDIR}/${P}-clip.patch"
}

src_install() {
	insinto /etc
	doins mime.types || die

	if use clip; then
		cat "${FILESDIR}/mime.types.clip" >> "${D}${CPREFIX}/etc/mime.types"
	fi
}
