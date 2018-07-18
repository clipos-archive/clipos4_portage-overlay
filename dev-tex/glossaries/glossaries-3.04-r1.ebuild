# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-tex/glossaries/glossaries-3.04.ebuild,v 1.14 2013/05/17 16:26:32 aballier Exp $

EAPI=5

inherit latex-package deb

DESCRIPTION="Create glossaries and lists of acronyms."
HOMEPAGE="http://www.ctan.org/tex-archive/help/Catalogue/entries/glossaries.html"
SRC_URI="mirror://gentoo/${P}.zip"

LICENSE="LPPL-1.2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos"
IUSE="doc examples clip-deps"

RDEPEND="!clip-deps? ( dev-lang/perl )
	dev-texlive/texlive-latexrecommended
	>=dev-texlive/texlive-latexextra-2012"
DEPEND="${RDEPEND}
	app-arch/unzip"

TEXMF="${CPREFIX}/share/texmf-site"
S=${WORKDIR}/${PN}

src_install() {
	latex-package_src_doinstall styles

	dobin makeglossaries

	dodoc CHANGES README
	insinto "${TEXMF}/tex/latex/${PN}/dict"
	doins *.dict
	if use doc ; then
		latex-package_src_doinstall pdf
	fi
	if use examples ; then
		docinto examples
		dodoc samples/*.tex
	fi
}

pkg_predeb() {
	init_maintainer "postinst"
	cat << EOF >> "${D}"/DEBIAN/postinst

${CPREFIX:-/usr}/sbin/texmf-update

EOF
}

