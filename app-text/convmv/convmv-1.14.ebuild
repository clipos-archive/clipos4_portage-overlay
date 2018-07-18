# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/convmv/convmv-1.14.ebuild,v 1.2 2010/02/21 03:53:20 abcd Exp $

EAPI=3

inherit eutils

DESCRIPTION="convert filenames to utf8 or any other charset"
HOMEPAGE="http://j3e.de/linux/convmv"
SRC_URI="http://j3e.de/linux/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sparc x86"
IUSE=""

DEPEND="dev-lang/perl"
RDEPEND=""

src_prepare() {
	sed -i -e "1s|#!/usr|#!${EPREFIX}${CPREFIX:-/usr}|" convmv || die
}

src_install() {
	einstall DESTDIR="${D}" PREFIX="${EPREFIX}${CPREFIX:-/usr}" || die "einstall failed"
	dodoc CREDITS Changes TODO VERSION

	if [[ -n "${CPREFIX}" ]]; then
		sed -i -e "s|${CPREFIX}/bin/perl|/usr/bin/perl|" "${D}${CPREFIX}/bin/convmv" || die
	fi
}

src_test() {
	unpack ./testsuite.tar

	cd "${S}"/suite
	./dotests.sh || die "Tests failed"
}
