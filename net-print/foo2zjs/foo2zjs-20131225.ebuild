# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-print/foo2zjs/foo2zjs-99999999.ebuild,v 1.13 2014/01/05 21:57:05 dilfridge Exp $

EAPI=4

inherit eutils

DESCRIPTION="Support for printing to ZjStream-based printers"
HOMEPAGE="http://foo2zjs.rkkda.com/"

# Yeah, upstream distfile is unversioned
SRC_URI="${HOMEPAGE}/${PN}.tar.gz -> ${P}.tar.gz"
KEYWORDS="x86 ~amd64 ~ppc"
IUSE="test foomaticdb clip"
RESTRICT="bindist"

LICENSE="GPL-2"
SLOT="0"
RDEPEND="net-print/cups
	foomaticdb? ( net-print/foomatic-db-engine )
	|| ( >=net-print/cups-filters-1.0.43-r1[foomatic] net-print/foomatic-filters )
	!clip? ( virtual/udev )"
DEPEND="${RDEPEND}
	app-arch/unzip
	test? ( sys-process/time )"


S=${WORKDIR}/${PN}

src_prepare() {
	epatch "${FILESDIR}/${PN}-udev.patch"
	epatch "${FILESDIR}/${PN}-usbbackend.patch"
	epatch "${FILESDIR}/${PN}-CLIP-Makefile.patch"

	# Prevent an access violation.
	sed -e "s~/etc~${D}/etc~g" -i Makefile
	sed -e "s~/etc~${D}/etc~g" -i hplj1000

	# Prevent an access violation, do not create symlinks on live file system
	# during installation.
	sed -e 's/ install-filter / /g' -i Makefile

	# Prevent an access violation, do not remove files from live filesystem
	# during make install
	sed -e '/rm .*LIBUDEVDIR)\//d' -i Makefile
	sed -e '/rm .*lib\/udev\/rules.d\//d' -i hplj1000
}

src_compile() {
	MAKEOPTS=-j1 default
}

src_install() {
	# ppd files are installed automagically. We have to create a directory
	# for them.
	dodir "/usr/share/ppd"

	emake DESTDIR="${D}/${CPREFIX:-/usr}/" install
	if ! use clip; then
		emake DESTDIR="${D}/${CPREFIX:-/usr}/" install-hotplug
	fi
}


