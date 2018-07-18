# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/xdialog/xdialog-2.3.1.ebuild,v 1.9 2012/05/13 15:53:32 hasufell Exp $

EAPI=2

inherit autotools eutils verictl2

DESCRIPTION="drop-in replacement for cdialog using GTK"
HOMEPAGE="http://xdialog.free.fr/"
SRC_URI="http://${PN}.free.fr/Xdialog-${PV}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~hppa ~ppc x86"
IUSE="doc examples nls clip clip-livecd clip-devstation"

RDEPEND=">=x11-libs/gtk+-2.2:2"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( sys-devel/gettext )"

S=${WORKDIR}/${P/x/X}

src_prepare() {
	epatch "${FILESDIR}"/${P}-{no-strip,install}.patch
	if use clip; then
		epatch "${FILESDIR}/xdialog-2.3.1-clip-hidepasswd.patch"
		epatch "${FILESDIR}/xdialog-2.3.1-clip-spinbutton.patch"
		epatch "${FILESDIR}/xdialog-2.3.1-clip-noprint.patch"
	fi
	eautoreconf
}

src_configure() {
	econf \
		$(use_enable nls) \
		--with-gtk2
}

src_install() {
	emake DESTDIR="${D}" install || die
	rm -rf "${D}"/usr/share/doc

	dodoc AUTHORS BUGS ChangeLog README

	use doc && dohtml -r doc/

	if use examples; then
		insinto /usr/share/doc/${PF}/examples
		doins samples/*
	fi

	if use clip; then
		exeinto /usr/bin
		doexe "${FILESDIR}"/xdialog.sh
	fi
	if use clip || use clip-livecd || use clip-devstation; then
		insinto /usr/share/icons
		doins "${FILESDIR}/dialog-"*.png
	fi
}

pkg_predeb() {
	VERIEXEC_CTX=503 doverictld2  ${CPREFIX:-/usr}/bin/Xdialog e - - - c 
	VERIEXEC_CTX=504 doverictld2  ${CPREFIX:-/usr}/bin/Xdialog e - - - c 
}
