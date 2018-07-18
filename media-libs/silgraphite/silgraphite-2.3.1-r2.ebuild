# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-libs/silgraphite/silgraphite-2.3.1.ebuild,v 1.28 2013/03/03 08:43:34 vapier Exp $

EAPI=4

inherit eutils

DESCRIPTION="Rendering engine for complex non-Roman writing systems"
HOMEPAGE="http://graphite.sil.org/"
SRC_URI="mirror://sourceforge/${PN}/${PV}/${P}.tar.gz"

LICENSE="|| ( CPL-0.5 LGPL-2.1 )"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="pango static-libs truetype xft"

RDEPEND="xft? ( x11-libs/libXft )
	truetype? ( media-libs/freetype:2 )
	pango? ( x11-libs/pango media-libs/fontconfig )"
DEPEND="${RDEPEND}
	virtual/pkgconfig"

src_prepare() {
	epatch "${FILESDIR}/${P}-aligned_access.patch"

	# Drop DEPRECATED flags, bug #385533
	sed -i -e 's:-D[A-Z_]*DISABLE_DEPRECATED:$(NULL):g' \
		wrappers/pangographite/Makefile.am wrappers/pangographite/Makefile.in \
		wrappers/pangographite/graphite/Makefile.am || die
}

src_configure() {
	econf \
		$(use_enable static-libs static) \
		$(use_with xft) \
		$(use_with truetype freetype) \
		$(use_with pango pangographite)
}

src_install() {
	local pkgconfigdir=$(pkg-config --variable=pc_path pkg-config | cut -d: -f1)
	local npkgconfigdir=${pkgconfigdir:-/usr/lib/pkgconfig}
	local cpkgconfigdir=${CPREFIX:-/usr}${npkgconfigdir#/usr}
	emake DESTDIR="${D}" install pkgconfigdir=${cpkgconfigdir} || die
	dodoc README
	find "${ED}" -name '*.la' -exec rm -f {} +
}
