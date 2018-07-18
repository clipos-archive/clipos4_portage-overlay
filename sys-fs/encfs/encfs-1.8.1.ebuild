# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
inherit autotools eutils multilib verictl2

DESCRIPTION="An implementation of encrypted filesystem in user-space using FUSE"
DESCRIPTION_FR="Système de fichiers pour le chiffrement à la volée de fichiers (nom et contenu)"
CATEGORY_FR="Système de fichiers"
HOMEPAGE="https://vgough.github.io/encfs/"
SRC_URI="https://github.com/vgough/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 ~arm ~sparc x86"
IUSE="xattr nls"
IUSE+=" clip-deps clip-rm clip-devstation"

RDEPEND="dev-libs/boost:=
	dev-libs/openssl:0
	>=dev-libs/rlog-1.3
	!clip-rm? ( !clip-devstation? ( >=sys-fs/fuse-2.5 ) )
	clip-rm? ( >=sys-fs/fuse-2.9.3-r1 )
	clip-devstation? ( >=sys-fs/fuse-2.9.3-r1 )
	!clip-deps? ( sys-libs/zlib )"
# Your libc probably provides xattrs, but to be safe
# we'll dep on sys-apps/attr.  This should be fixed
# if we ever create a virtual/attr.
DEPEND="${RDEPEND}
	dev-lang/perl
	virtual/pkgconfig
	xattr? ( sys-apps/attr )
	nls? ( sys-devel/gettext )"

src_prepare() {
	use clip-rm && epatch "${FILESDIR}/${PN}-${PV}-clip-sgid.patch"
	eautoreconf
}

src_configure() {
	# configure searches for either attr/xattr.h or sys/xattr.h
	use xattr || export ac_cv_header_{attr,sys}_xattr_h=no

	econf \
		$(use_enable nls) \
		--disable-valgrind \
		--enable-openssl \
		--disable-dependency-tracking
}

src_install() {
	emake DESTDIR="${D}" install || die
	dodoc AUTHORS ChangeLog README.md
	find "${D}" -name '*.la' -delete

	if use clip-rm; then
		chown 0:350 "${D}${CPREFIX:-/usr}/bin/encfs"
		chmod 2711 "${D}${CPREFIX:-/usr}/bin/encfs"
	fi
}

pkg_predeb() {
	doverictld2 "${CPREFIX:-/usr}/bin/encfs" e - - - f
}
