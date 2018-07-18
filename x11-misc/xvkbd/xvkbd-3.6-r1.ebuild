# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils multilib toolchain-funcs

DESCRIPTION="virtual keyboard for X window system"
HOMEPAGE="http://homepage3.nifty.com/tsato/xvkbd/"
SRC_URI="http://homepage3.nifty.com/tsato/xvkbd/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="clip clip-livecd"

RDEPEND="
	x11-libs/libX11
	x11-libs/libXaw
	x11-libs/libXaw3d[unicode]
	x11-libs/libXmu
	x11-libs/libXt
	x11-libs/libXtst
	clip? ( media-gfx/cellwriter )
"
DEPEND="
	${RDEPEND}
	app-text/rman
	x11-misc/gccmakedep
	x11-misc/imake
	x11-proto/inputproto
	x11-proto/xextproto
	x11-proto/xproto
"

src_prepare() {
	epatch "${FILESDIR}"/${P}-last_altgr_mask.patch

	epatch_user
}

src_configure() {
	xmkmf -a || die
}

src_compile() {
	emake \
		CC=$(tc-getCC) LD=$(tc-getCC) \
		XAPPLOADDIR="${CPREFIX:-/usr}/share/X11/app-defaults" \
		LOCAL_LDFLAGS="${LDFLAGS}" \
		CDEBUGFLAGS="${CFLAGS}"
}

src_install() {
	emake \
		XAPPLOADDIR="${CPREFIX:-/usr}/share/X11/app-defaults" \
		BINDIR="${CPREFIX:-/usr}/bin" \
		DESTDIR="${D}" \
		install

	rm -r "${D}"/usr/$(get_libdir) "${D}"/etc || die

	dodoc README
	newman ${PN}.man ${PN}.1

	if use clip; then
		exeinto /usr/bin
		doexe "${FILESDIR}"/toggle_kbd.sh
		insinto /etc
		doins "${FILESDIR}"/XVkbd.resources
	fi

	if use clip-livecd; then
		exeinto /usr/bin
		newexe "${FILESDIR}"/toggle_kbd.sh.livecd toggle_kbd.sh
		insinto /etc
		doins "${FILESDIR}"/XVkbd.resources
	fi
}