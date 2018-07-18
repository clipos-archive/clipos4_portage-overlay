# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-dns/bind-tools/bind-tools-9.9.2.ebuild,v 1.9 2012/12/16 17:39:10 armin76 Exp $

EAPI="4"

inherit eutils autotools flag-o-matic toolchain-funcs verictl2

MY_PN=${PN//-tools}
MY_PV=${PV/_p/-P}
MY_PV=${MY_PV/_rc/rc}
MY_P="${MY_PN}-${MY_PV}"

DESCRIPTION="bind tools: dig, nslookup, host, nsupdate, dnssec-keygen"
DESCRIPTION_FR="Outils de test DNS: dig, nslookup, host, nsupdate"
CATEGORY_FR="Réseau"
HOMEPAGE="http://www.isc.org/software/bind"
SRC_URI="ftp://ftp.isc.org/isc/bind9/${MY_PV}/${MY_P}.tar.gz"

LICENSE="ISC BSD BSD-2 HPND JNIC RSA openssl"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="doc gssapi idn ipv6 readline ssl urandom xml clip-deps core-deps"
# no PKCS11 currently as it requires OpenSSL to be patched, also see bug 409687

DEPEND="
	!core-deps? ( 
		ssl? ( dev-libs/openssl ) 
		readline? ( sys-libs/readline )
	)
	xml? ( dev-libs/libxml2 )
	idn? ( net-dns/idnkit )
	gssapi? ( virtual/krb5 )"
RDEPEND="${DEPEND}"

S="${WORKDIR}/${MY_P}"

src_prepare() {
	# bug 231247
	epatch "${FILESDIR}"/${PN}-9.5.0_p1-lwconfig.patch

	# Disable tests for now, bug 406399
	sed -i '/^SUBDIRS/s:tests::' bin/Makefile.in lib/Makefile.in || die

	# bug #220361
	rm {aclocal,libtool}.m4
	eautoreconf
}

src_configure() {
	local myconf=

	if use urandom; then
		myconf="${myconf} --with-randomdev=/dev/urandom"
	else
		myconf="${myconf} --with-randomdev=/dev/random"
	fi

	# bug 344029
	append-cflags "-DDIG_SIGCHASE"

	# localstatedir for nsupdate -l, bug 395785
	tc-export BUILD_CC
	econf \
		--localstatedir=/var \
		--without-python \
		$(use_enable ipv6) \
		$(use_with idn) \
		$(use_with ssl openssl "${EPREFIX}"/usr) \
		$(use_with xml libxml2) \
		$(use_with gssapi) \
		$(use_with readline) \
		${myconf}

	# bug #151839
	echo '#undef SO_BSDCOMPAT' >> config.h
}

src_compile() {
	local AR=$(tc-getAR)

	emake AR=$AR -C lib/ || die "emake lib failed"
	emake AR=$AR -C bin/dig/ || die "emake bin/dig failed"
	emake AR=$AR -C bin/nsupdate/ || die "emake bin/nsupdate failed"
	emake AR=$AR -C bin/dnssec/ || die "emake bin/dnssec failed"
}

src_install() {
	dodoc README CHANGES FAQ

	cd "${S}"/bin/dig
	dobin dig host nslookup
	doman {dig,host,nslookup}.1

	cd "${S}"/bin/nsupdate
	dobin nsupdate
	doman nsupdate.1
	if use doc; then
		dohtml nsupdate.html
	fi

	cd "${S}"/bin/dnssec
	dobin dnssec-keygen
	doman dnssec-keygen.8
	if use doc; then
		dohtml dnssec-keygen.html
	fi
}

pkg_predeb() {
	doverictld2  ${CPREFIX:-/usr}/bin/dig e - - - c ccsd
	doverictld2  ${CPREFIX:-/usr}/bin/host e - - - c ccsd
	doverictld2  ${CPREFIX:-/usr}/bin/nslookup e - - - c ccsd
	doverictld2  ${CPREFIX:-/usr}/bin/nsupdate e - - - c ccsd
}
