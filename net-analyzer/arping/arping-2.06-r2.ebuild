# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-analyzer/arping/arping-2.06.ebuild,v 1.9 2008/11/09 12:10:38 vapier Exp $

inherit toolchain-funcs verictl2

DESCRIPTION="A utility to see if a specific IP address is taken and what MAC address owns it"
HOMEPAGE="http://www.habets.pp.se/synscan/programs.php?prog=arping"
SRC_URI="ftp://ftp.habets.pp.se/pub/synscan/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="2"
KEYWORDS="amd64 arm hppa ~ia64 ppc ppc64 s390 sh sparc x86"
IUSE=""

DEPEND="net-libs/libpcap
	>=net-libs/libnet-1.1.0-r3"

src_unpack() {
	unpack ${A}
	cd "${S}"
	rm -f Makefile
	# since we install as arping2, use arping2 in the man page
	sed -i "s/\(${PN}\)/\12/g" ${PN}.8 || die "sed ${PN}.8 failed"
}

src_compile() {
	emake \
		CC=$(tc-getCC) \
		LDLIBS="-lpcap -lnet" \
		arping-2/arping \
		|| die
}

src_test() {
	einfo "Selftest only works as root"
	#make SUDO= HOST=`hostname` MAC=`ifconfig -a | fgrep HWaddr | sed 's/.*HWaddr //g'` test
}

src_install() {
	newsbin arping-2/arping arping2 || die
	newman arping.8 arping2.8
	dodoc README arping-scan-net.sh
}

pkg_predeb() {
	# CLSM_PRIV_NET{CLIENT,SERVER,LINK}
	# CAP_NET_RAW + CAP_NET_ADMIN, inheritable
	doverictld2 ${CPREFIX:-/usr}/sbin/arping2 er 'NET_ADMIN|NET_RAW' - 'NET_ADMIN|NET_RAW' csN ccsd
}