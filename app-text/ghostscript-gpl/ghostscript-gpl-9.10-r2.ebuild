# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-text/ghostscript-gpl/ghostscript-gpl-9.10-r2.ebuild,v 1.11 2014/06/10 01:04:39 vapier Exp $

EAPI=5

inherit autotools eutils multilib versionator flag-o-matic pax-utils

DESCRIPTION="Ghostscript is an interpreter for the PostScript language and for PDF"
HOMEPAGE="http://ghostscript.com/"

MY_P=${P/-gpl}
GSDJVU_PV=1.6
PVM=$(get_version_component_range 1-2)
SRC_URI="
	mirror://sourceforge/ghostscript/${MY_P}.tar.bz2
	mirror://gentoo/${PN}-9.10-patchset-1.tar.bz2
	!bindist? ( djvu? ( mirror://sourceforge/djvu/gsdjvu-${GSDJVU_PV}.tar.gz ) )"

LICENSE="AGPL-3 CPL-1.0"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~sparc-fbsd ~x86-fbsd"
IUSE="bindist cups dbus djvu gtk idn linguas_de static-libs X"
IUSE="${IUSE} clip clip-deps core-deps"

COMMON_DEPEND="
	app-text/libpaper
	media-libs/fontconfig
	!core-deps? ( 
		>=media-libs/freetype-2.4.9:2=
		virtual/jpeg:0
		>=media-libs/libpng-1.6.2:0=
	)
	!clip-deps? ( 
		>=sys-libs/zlib-1.2.7:=
	)
	media-libs/jbig2dec
	>=media-libs/lcms-2.5:2
	>=media-libs/tiff-4.0.1:0=
	!bindist? ( djvu? ( app-text/djvu ) )
	cups? ( >=net-print/cups-1.3.8 )
	dbus? ( sys-apps/dbus )
	gtk? ( || ( x11-libs/gtk+:3 x11-libs/gtk+:2 ) )
	idn? ( net-dns/libidn )
	X? ( x11-libs/libXt x11-libs/libXext )
"

DEPEND="${COMMON_DEPEND}
	virtual/pkgconfig
"

RDEPEND="${COMMON_DEPEND}
	>=app-text/poppler-data-0.4.5-r1
	>=media-fonts/urw-fonts-2.4.9
	linguas_ja? ( media-fonts/kochi-substitute )
	linguas_ko? ( media-fonts/baekmuk-fonts )
	linguas_zh_CN? ( media-fonts/arphicfonts )
	linguas_zh_TW? ( media-fonts/arphicfonts )
	!!media-fonts/gnu-gs-fonts-std
	!!media-fonts/gnu-gs-fonts-other
	!<net-print/cups-filters-1.0.36-r2
"

S="${WORKDIR}/${MY_P}"

LANGS="ja ko zh_CN zh_TW"
for X in ${LANGS} ; do
	IUSE="${IUSE} linguas_${X}"
done

pkg_setup() {
	if use bindist && use djvu; then
		ewarn "You have bindist in your USE, djvu support will NOT be compiled!"
		ewarn "See http://djvu.sourceforge.net/gsdjvu/COPYING for details on licensing issues."
	fi
}

src_prepare() {
	# remove internal copies of various libraries
	rm -rf "${S}"/cups/libs
	rm -rf "${S}"/expat
	rm -rf "${S}"/freetype
	rm -rf "${S}"/jbig2dec
	rm -rf "${S}"/jpeg{,xr}
	rm -rf "${S}"/lcms{,2}
	rm -rf "${S}"/libpng
	rm -rf "${S}"/tiff
	rm -rf "${S}"/zlib
	# remove internal urw-fonts
	rm -rf "${S}"/Resource/Font
	# remove internal CMaps (CMaps from poppler-data are used instead)
	rm -rf "${S}"/Resource/CMap

	# apply various patches, many borrowed from Fedora
	# http://pkgs.fedoraproject.org/gitweb/?p=ghostscript.git
	EPATCH_SUFFIX="patch" EPATCH_FORCE="yes"
	EPATCH_SOURCE="${WORKDIR}/patches/"
	epatch

	if ! use bindist && use djvu ; then
		unpack gsdjvu-${GSDJVU_PV}.tar.gz
		cp gsdjvu-${GSDJVU_PV}/gsdjvu "${S}"
		cp gsdjvu-${GSDJVU_PV}/gdevdjvu.c "${S}"/base
		epatch "${WORKDIR}"/patches-gsdjvu/gsdjvu-1.3-${PN}-8.64.patch
		cp "${S}"/contrib/contrib.mak "${S}"/base/contrib.mak.gsdjvu
		grep -q djvusep "${S}"/contrib/contrib.mak || \
			cat gsdjvu-${GSDJVU_PV}/gsdjvu.mak >> "${S}"/contrib/contrib.mak

		# install ps2utf8.ps, bug #197818
		cp gsdjvu-${GSDJVU_PV}/ps2utf8.ps "${S}"/lib
		sed -i -e '/$(EXTRA_INIT_FILES)/ a\ps2utf8.ps \\' \
			"${S}"/base/unixinst.mak || die "sed failed"
	fi

	if ! use gtk ; then
		sed -i -e "s:\$(GSSOX)::" \
			-e "s:.*\$(GSSOX_XENAME)$::" \
			"${S}"/base/unix-dll.mak || die "sed failed"
	fi

	# search path fix
	sed -i -e "s:\$\(gsdatadir\)/lib:${CPREFIX:-/usr}/share/ghostscript/${PVM}/$(get_libdir):" \
		-e "s:exdir=.*:exdir=${CPREFIX:-/usr}/share/doc/${PF}/examples:" \
		-e "s:docdir=.*:docdir=${CPREFIX:-/usr}/share/doc/${PF}/html:" \
		-e "s:GS_DOCDIR=.*:GS_DOCDIR=${CPREFIX:-/usr}/share/doc/${PF}/html:" \
		-e 's:-L$(BINDIR):$(LDFLAGS) &:g' \
		"${S}"/Makefile.in "${S}"/base/*.mak || die "sed failed"

	cd "${S}"
	eautoreconf

	cd "${S}/ijs"
	eautoreconf
}

src_configure() {
	local FONTPATH
	for path in \
		${CPREFIX:-/usr}/share/fonts/urw-fonts \
		${CPREFIX:-/usr}/share/fonts/Type1 \
		${CPREFIX:-/usr}/share/fonts \
		${CPREFIX:-/usr}/share/poppler/cMap/Adobe-CNS1 \
		${CPREFIX:-/usr}/share/poppler/cMap/Adobe-GB1 \
		${CPREFIX:-/usr}/share/poppler/cMap/Adobe-Japan1 \
		${CPREFIX:-/usr}/share/poppler/cMap/Adobe-Japan2 \
		${CPREFIX:-/usr}/share/poppler/cMap/Adobe-Korea1
	do
		FONTPATH="$FONTPATH${FONTPATH:+:}$path"
	done

	econf \
		--enable-dynamic \
		--enable-freetype \
		--enable-fontconfig \
		--enable-openjpeg \
		--disable-compile-inits \
		--with-drivers=ALL \
		--with-fontpath="$FONTPATH" \
		--with-ijs \
		--with-jbig2dec \
		--with-libpaper \
		--with-system-libtiff \
		--without-lcms \
		--without-luratech \
		$(use_enable cups) \
		$(use_enable dbus) \
		$(use_enable gtk) \
		$(use_with cups pdftoraster) \
		$(use_with idn libidn) \
		$(use_with X x)

	if ! use bindist && use djvu ; then
		sed -i -e 's!$(DD)bbox.dev!& $(DD)djvumask.dev $(DD)djvusep.dev!g' \
			|| die "sed failed"
	fi

	if [[ -n "${CPREFIX}" ]] ; then
		# I'm just too lazy to fix this in configure...
		sed -i \
			-e "s:CUPSSERVERBIN=/usr/libexec:CUPSSERVERBIN=${CPREFIX}/lib:g" \
			-e "s:CUPSSERVERROOT=/etc/cups:CUPSSERVERROOT=${CPREFIX}/etc/cups:g" \
			-e "s:CUPSDATA=/usr/share:CUPSDATA=${CPREFIX}/share:g" \
			"${S}"/Makefile || die "sed failed"
	fi

	cd "${S}/ijs"
	econf \
		--enable-shared \
		$(use_enable static-libs static)
}

src_compile() {
	# workaround: -j1 -> see bug #234378
	emake -j1 so all

	cd "${S}/ijs"
	emake
}

src_install() {
	# workaround: -j1 -> see bug #356303
	emake -j1 DESTDIR="${D}" install-so install

	local cupsdir=libexec
	use clip && cupsdir=$(get_libdir)

	if ! use bindist && use djvu ; then
		dobin gsdjvu
	fi

	# remove gsc in favor of gambit, bug #253064
	rm -rf "${D}${CPREFIX:-/usr}/bin/gsc"

	cd "${S}/ijs"
	emake DESTDIR="${D}" install

	# rename the original cidfmap to cidfmap.GS
	mv "${D}${CPREFIX:-/usr}/share/ghostscript/${PVM}/Resource/Init/cidfmap"{,.GS} || die

	# install our own cidfmap to handle CJK fonts
	insinto "/usr/share/ghostscript/${PVM}/Resource/Init"
	doins "${WORKDIR}/fontmaps/CIDFnmap"
	doins "${WORKDIR}/fontmaps/cidfmap"
	for X in ${LANGS} ; do
		if use linguas_${X} ; then
			doins "${WORKDIR}/fontmaps/cidfmap.${X}"
		fi
	done

	# install the CMaps from poppler-data properly, bug 409361
	dosym /usr/share/poppler/cMaps /usr/share/ghostscript/${PVM}/Resource/CMap

	use static-libs || find "${D}" -name '*.la' -delete
	use clip && pax-mark 'L' "${D}${CPREFIX:-/usr}/bin/gs"

	use linguas_de || rm -r "${D}"${CPREFIX:-/usr}/share/man/de
}
