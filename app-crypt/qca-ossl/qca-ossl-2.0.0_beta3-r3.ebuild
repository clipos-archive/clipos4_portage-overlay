# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/www/viewcvs.gentoo.org/raw_cvs/gentoo-x86/app-crypt/qca-ossl/qca-ossl-2.0.0_beta3-r1.ebuild,v 1.7 2009/11/13 12:54:58 josejx Exp $

EAPI="2"

inherit eutils qt4-r2

MY_P="${P/_/-}"
QCA_VER="${PV%.*}"

DESCRIPTION="TLS, S/MIME, PKCS#12, crypto algorithms plugin for QCA"
HOMEPAGE="http://delta.affinix.com/qca/"
SRC_URI="http://delta.affinix.com/download/qca/${QCA_VER}/plugins/${MY_P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="alpha amd64 hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd"
IUSE="debug core-deps"

DEPEND=">=app-crypt/qca-${QCA_VER}[debug?]
	!core-deps? ( >=dev-libs/openssl-0.9.6 )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

PATCHES=( "${FILESDIR}/${PN}-openssl-1.0.0.patch" )

src_configure() {
	# cannot use econf because of non-standard configure script
	./configure \
		--qtdir=${CPREFIX:-/usr} \
		$(use debug && echo "--debug" || echo "--release") \
		--no-separate-debug-info \
		|| die "configure failed"

	sed -i -e "s:/usr:${CPREFIX:-/usr}:" conf.pri

	eqmake4
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die
}
