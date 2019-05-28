# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/dvipdfmx/dvipdfmx-20110311.ebuild,v 1.3 2011/10/05 23:26:17 aballier Exp $

EAPI=2
inherit autotools eutils texlive-common

DESCRIPTION="DVI to PDF translator with multi-byte character support"
HOMEPAGE="http://project.ktug.or.kr/dvipdfmx/"
SRC_URI="http://project.ktug.or.kr/${PN}/snapshot/latest/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd"
IUSE="clip-deps core-deps clip"

DEPEND="app-text/libpaper
	!core-deps? ( media-libs/libpng )
	!clip-deps? ( sys-libs/zlib )
	!clip? ( virtual/tex-base )
	app-text/libpaper"
RDEPEND="${DEPEND}
	>=app-text/poppler-0.12.3-r3
	app-text/poppler-data"

src_prepare() {
	epatch "${FILESDIR}"/20090708-fix_file_collisions.patch
	sed -e "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/" -i configure.in || die
	eautoreconf
}

src_install() {
	# Override dvipdfmx.cfg default installation location so that it is easy to
	# modify it and it gets config protected. Symlink it from the old location.
	emake configdatadir="${EPREFIX}${CPREFIX}/etc/texmf/dvipdfmx" \
		glyphlistdatadir="${EPREFIX}${CPREFIX:-/usr}/share/texmf-site/fonts/map/glyphlist" \
		mapdatadir="${EPREFIX}${CPREFIX:-/usr}/share/texmf-site/fonts/map/dvipdfmx" \
		DESTDIR="${D}" \
		install || die
	dosym /etc/texmf/dvipdfmx/dvipdfmx.cfg /usr/share/texmf-site/dvipdfmx/dvipdfmx.cfg || die

	# Symlink poppler-data cMap, bug #201258
	dosym /usr/share/poppler/cMap /usr/share/texmf-site/fonts/cmap/cMap || die
	dodoc AUTHORS ChangeLog README || die

	# Remove symlink conflicting with app-text/dvipdfm (bug #295235)
	rm "${D}${CPREFIX:-/usr}"/bin/ebb
}

pkg_postinst() {
	etexmf-update
}

pkg_postrm() {
	etexmf-update
}
