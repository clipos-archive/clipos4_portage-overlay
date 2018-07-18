# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KDE_HANDBOOK="optional"
KMNAME="kde-baseapps"
inherit flag-o-matic kde4-meta pax-utils verictl2

DESCRIPTION="KDE: Web browser and file manager"
HOMEPAGE="
	https://www.kde.org/applications/internet/konqueror/
	http://konqueror.org/
"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="+bookmarks debug svg"
IUSE="${IUSE} clip"
# 4 of 4 tests fail. Last checked for 4.0.3
RESTRICT="test"

DEPEND="
	$(add_kdeapps_dep libkonq)
"

# bug #544630: evince[nsplugin] crashes konqueror
RDEPEND="${DEPEND}
	$(add_kdeapps_dep kfind)
	$(add_kdeapps_dep kfmclient)
	$(add_kdeapps_dep kurifilter-plugins)
	bookmarks? ( $(add_kdeapps_dep keditbookmarks) )
	svg? ( $(add_kdeapps_dep svgpart) )
	!app-text/evince[nsplugin]
	clip? ( !kde-base/kdebase-apps )
"

KMEXTRACTONLY="
	konqueror/client/
	lib/konq/
"

src_prepare() {
	[[ ${CHOST} == *-solaris* ]] && append-ldflags -lmalloc

	kde4-meta_src_prepare

	# Do not install *.desktop files for kfmclient
	sed -e "/kfmclient\.desktop/d" -i konqueror/CMakeLists.txt \
		|| die "Failed to omit .desktop files"
}

src_install() {
	kde4-meta_src_install

	pax-mark L "${ED}${KDEDIR}/bin/konqueror" || die "pax-mark failed"

	if use clip; then
		rm -fr "${D}/var"

		ebegin "Cleaning templates"
			rm "${D}/${CPREFIX:-/usr}/share/templates/"{HTMLFile.desktop,.source/HTMLFile.html}
	grep -rlE '^(Name=.* Device...|Name=NFS...|Type=FSDevice)$' "${D}/${CPREFIX:-/usr}/share/templates/" | while read f; do
		rm -f -- "$f" 
		done 
		eend $?

	# Don't  show  in  menus
		echo "NoDisplay=true" >> "${ED}${CPREFIX:-/usr}/share/applications/kde4/konqbrowser.desktop" \ || die ""
	fi
}


pkg_postinst() {
	kde4-meta_pkg_postinst

	if ! has_version kde-apps/dolphin:${SLOT} ; then
		elog "If you want to use konqueror as a filemanager, install the dolphin kpart:"
		elog "kde-apps/dolphin:${SLOT}"
	fi

	if ! has_version virtual/jre ; then
		elog "To use Java on webpages install virtual/jre."
	fi
}

pkg_predeb() {
	doverictld2  ${CPREFIX:-/usr}/bin/konqueror e - - - c
}
