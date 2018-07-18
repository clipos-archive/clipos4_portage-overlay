# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils autotools

DESCRIPTION="Libraries and applications to access smartcards"
HOMEPAGE="https://github.com/OpenSC/OpenSC/wiki"
SRC_URI="https://github.com/OpenSC/OpenSC/releases/download/${PV}/${P}.tar.gz"

LICENSE="LGPL-2.1"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~m68k ppc ppc64 ~s390 ~sh sparc x86"
IUSE="doc +pcsc-lite secure-messaging openct ctapi readline libressl ssl zlib"
IUSE="$IUSE clip"

RDEPEND="zlib? ( sys-libs/zlib )
	readline? ( sys-libs/readline:0= )
	ssl? (
		!libressl? ( dev-libs/openssl:0= )
		libressl? ( dev-libs/libressl:0= )
	)
	openct? ( >=dev-libs/openct-0.5.0 )
	pcsc-lite? ( >=sys-apps/pcsc-lite-1.3.0 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	app-text/docbook-xsl-stylesheets
	dev-libs/libxslt"

REQUIRED_USE="
	pcsc-lite? ( !openct !ctapi )
	openct? ( !pcsc-lite !ctapi )
	ctapi? ( !pcsc-lite !openct )
	|| ( pcsc-lite openct ctapi )"

src_prepare() {
	epatch "${FILESDIR}"/The_UNBLOCKING_PIN_is_the_SO_PIN_on_ias_ecc_cards.patch
	epatch "${FILESDIR}"/opensc-0.16.0-fix_minint_card.patch
	eautoreconf
}

src_configure() {
	econf \
		--sysconfdir="/etc/opensc" \
		--docdir="/usr/share/doc/${PF}" \
		--htmldir='$(docdir)/html' \
		--disable-static \
		$(use_enable doc) \
		$(use_enable openct) \
		$(use_enable readline) \
		$(use_enable zlib) \
		$(use_enable secure-messaging sm) \
		$(use_enable ssl openssl) \
		$(use_enable pcsc-lite pcsc) \
		$(use_enable openct) \
		$(use_enable ctapi)
}

src_install() {
	default
	prune_libtool_files --all

	# CLIP: override config
	insinto /etc/opensc
	doins "$FILESDIR"/opensc.conf

	if use clip ; then
		rm -rf ${D}/usr/bin/
		rm -rf ${D}/usr/lib/pkcs11-spy.*
		rm -rf ${D}/usr/lib/pkcs11/pkcs11-spy.*
	fi
}
