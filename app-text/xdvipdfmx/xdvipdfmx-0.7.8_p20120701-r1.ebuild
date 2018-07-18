# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/xdvipdfmx/xdvipdfmx-0.7.8_p20120701.ebuild,v 1.13 2013/04/25 21:25:54 ago Exp $

EAPI="4"

DESCRIPTION="Extended dvipdfmx for use with XeTeX and other unicode TeXs."
HOMEPAGE="http://scripts.sil.org/svn-view/xdvipdfmx/
	http://tug.org/texlive/"
SRC_URI="mirror://gentoo/texlive-${PV#*_p}-source.tar.xz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris"
IUSE="doc clip-deps core-deps"

RDEPEND="!<app-text/texlive-core-2010
	dev-libs/kpathsea
	!clip-deps? ( sys-libs/zlib )
	media-libs/freetype:2
	media-libs/fontconfig
	!core-deps? ( 
		media-libs/freetype:2
		>=media-libs/libpng-1.2.43-r2:0
	)

	app-text/libpaper"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"
# for dvipdfmx.cfg
RDEPEND="${RDEPEND}
	app-text/dvipdfmx"

S=${WORKDIR}/texlive-${PV#*_p}-source/texk/${PN}

src_configure() {
	# don't do OSX stuff as it breaks on using long gone freetype funcs
	export kpse_cv_have_ApplicationServices=no

	econf \
		--with-system-kpathsea \
		--with-system-zlib \
		--with-system-libpng \
		--with-system-freetype2
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc README TODO BUGS AUTHORS ChangeLog ChangeLog.TL
	if use doc ; then
		insinto /usr/share/doc/${PF}
		doins -r doc
	fi
}
