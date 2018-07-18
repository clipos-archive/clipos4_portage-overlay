# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/qca/qca-2.0.3.ebuild,v 1.8 2011/08/17 16:42:26 chithanh Exp $

EAPI="3"
inherit eutils multilib qt4-r2

DESCRIPTION="Qt Cryptographic Architecture (QCA)"
HOMEPAGE="http://delta.affinix.com/qca/"
SRC_URI="http://delta.affinix.com/download/${PN}/${PV%.*}/${P}.tar.bz2"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~sparc-solaris"
IUSE="aqua debug doc examples"
RESTRICT="test"

DEPEND="dev-qt/qtcore:4[debug?]"
RDEPEND="${DEPEND}
	!<app-crypt/qca-1.0-r3:0"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-2.0.2-pcfilespath.patch \
		"${FILESDIR}"/${P}+gcc-4.7.patch


	if use aqua; then
		sed -i \
		-e "s|QMAKE_LFLAGS_SONAME =.*|QMAKE_LFLAGS_SONAME = -Wl,-install_name,|g" \
		src/src.pro || die "Sed failed."
	fi
}

src_configure() {
	_libdir=$(get_libdir)

	# Ensure proper rpath
	export EXTRA_QMAKE_RPATH="${EPREFIX}/usr/${_libdir}/qca2"

	ABI= ./configure \
		--prefix="${EPREFIX}${CPREFIX:-/usr}" \
		--qtdir="${EPREFIX}${CPREFIX:-/usr}" \
		--includedir="${EPREFIX}${CPREFIX:-/usr}"/include/qca2 \
		--libdir="${EPREFIX}${CPREFIX:-/usr}"/${_libdir}/qca2 \
		--certstore-path="${EPREFIX}${CPREFIX}"/etc/ssl/certs/ca-certificates.crt \
		--no-separate-debug-info \
		--disable-tests \
		--$(use debug && echo debug || echo release) \
		--no-framework \
		|| die "configure failed"

	if [[ -n "${CPREFIX}" ]]; then
		sed -i -e \
			"s:/usr/share/qt4/mkspecs/features:${CPREFIX}/share/qt4/mkspecs/features:" \
			"${S}/conf.pri" || die
	fi

	eqmake4
}

src_install() {
	emake INSTALL_ROOT="${D}" install || die
	dodoc README TODO || die

	cat <<-EOF > "${WORKDIR}"/44qca2
	LDPATH="${EPREFIX}${CPREFIX:-/usr}/${_libdir}/qca2"
	EOF
	doenvd "${WORKDIR}"/44qca2 || die

	if use doc; then
		dohtml "${S}"/apidocs/html/* || die
	fi

	if use examples; then
		insinto /usr/share/doc/${PF}/
		doins -r "${S}"/examples || die
	fi

	# add the proper rpath for packages that do CONFIG += crypto
	echo "QMAKE_RPATHDIR += \"${EPREFIX}${CPREFIX:-/usr}/${_libdir}/qca2\"" >> \
		"${D%/}${EPREFIX}${CPREFIX:-/usr}/share/qt4/mkspecs/features/crypto.prf" \
		|| die "failed to add rpath to crypto.prf"
}
