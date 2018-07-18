# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/paxctl/paxctl-0.7-r1.ebuild,v 1.4 2012/04/05 16:38:01 jer Exp $

EAPI="4"

inherit toolchain-funcs eutils

DESCRIPTION="Manages various PaX related program header flags for Elf32, Elf64, binaries."
SRC_URI="http://pax.grsecurity.net/${P}.tar.bz2"
HOMEPAGE="http://pax.grsecurity.net"
KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86"
IUSE="clip clip-devstation"
LICENSE="GPL-2"
SLOT="0"

DEPEND=">=sys-devel/binutils-2.14.90.0.8-r1"
RDEPEND=""

DOCS=( README ChangeLog )

src_prepare() {
	if use clip || use clip-devstation; then
		epatch "${FILESDIR}/${P}-clip-elfreloc.patch"
	fi
}

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}"
}
