# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/zim/zim-0.62.ebuild,v 1.1 2014/10/04 08:35:15 jer Exp $

EAPI=5

PYTHON_COMPAT=( python2_7 )
PYTHON_REQ_USE="sqlite"
DISTUTILS_SINGLE_IMPL=1

inherit distutils-r1 gnome2-utils fdo-mime virtualx script

DESCRIPTION="A desktop wiki"
DESCRIPTION_FR="Wiki de bureau (prise de notes)"
CATEGORY_FR="Bureautique"
HOMEPAGE="http://zim-wiki.org/"
SRC_URI="http://zim-wiki.org/downloads/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="test"
IUSE+=" clip"

CDEPEND="dev-python/pygtk[${PYTHON_USEDEP}]"
RDEPEND="${CDEPEND}
	clip? (
		dev-python/gtkspell-python
		app-text/dvipng
	)
"
DEPEND="${CDEPEND}
	x11-misc/xdg-utils
	test? (
		dev-vcs/bzr
		dev-vcs/git
		dev-vcs/mercurial )"

PATCHES=(
	"${FILESDIR}"/${PN}-0.60-remove-ubuntu-theme.patch
	"${FILESDIR}"/${P}-desktop.patch
)

python_prepare() {
	# CLIP: Do not use $LOGNAME, $USER is fine
	#sed -i -e "s/'USER'/'LOGNAME'/g" zim/__init__.py zim/fs.py || die

	if [[ ${LINGUAS} ]]; then
		local lingua
		for lingua in translations/*.po; do
			lingua=${lingua/.po}
			lingua=${lingua/translations\/}
			has ${lingua} ${LINGUAS} || \
				{ rm translations/${lingua}.po || die; }
		done
	fi

	distutils-r1_python_prepare
}

python_test() {
	VIRTUALX_COMMAND="${PYTHON}" virtualmake test.py
}

python_install() {
	distutils-r1_python_install --skip-xdg-cmd

	use clip && shebang_fix "${D}" 'python[\.0-9]*'
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
	if ! has_version ${CATEGORY}/${PN}; then
		einfo "Please emerge these packages for additional functionality"
		einfo "    dev-lang/R"
		einfo "    dev-python/gtkspell-python"
		einfo "    dev-vcs/bzr"
		einfo "    gnome-extra/zeitgeist"
		einfo "    media-gfx/graphviz"
		einfo "    media-gfx/imagemagick"
		einfo "    media-gfx/scrot"
		einfo "    media-sound/lilypond"
		einfo "    sci-visualization/gnuplot"
		einfo "    virtual/latex-base app-text/dvipng"
	fi
}

pkg_postrm() {
	fdo-mime_desktop_database_update
	gnome2_icon_cache_update
}
