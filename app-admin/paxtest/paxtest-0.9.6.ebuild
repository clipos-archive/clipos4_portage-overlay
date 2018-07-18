# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/paxtest/paxtest-0.9.6.ebuild,v 1.15 2006/09/08 05:51:14 corsair Exp $

inherit eutils multilib

DESCRIPTION="PaX regression test suite"
HOMEPAGE="http://www.adamantix.org/paxtest/"
SRC_URI="http://www.adamantix.org/paxtest/paxtest-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha ~amd64 arm ~hppa ia64 ~mips ppc ~ppc64 sparc x86"
IUSE="clip"
# pax flags are not strip safe.
RESTRICT="nostrip"

DEPEND="virtual/libc
	!clip? ( >=sys-apps/chpax-0.5 )"

src_unpack() {
	unpack ${A}
	cp ${FILESDIR}/Makefile-portable ${S}/Makefile
}

src_compile() {
	emake DESTDIR=${D} BINDIR=${D}/usr/bin RUNDIR=/usr/$(get_libdir)/paxtest || die
}

src_install() {
	make DESTDIR="${D}" BINDIR=/usr/bin RUNDIR=/usr/$(get_libdir)/paxtest install || die
	use clip && sed -i -e 's:paxtest.log:/tmp/paxtest.log:g' ${D}/usr/bin/paxtest
	for doc in Changelog README ;do
		[[ -f ${doc} ]] && dodoc ${doc}
	done
}