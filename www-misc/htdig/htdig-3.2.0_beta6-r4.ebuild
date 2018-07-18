# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

inherit eutils autotools

MY_PV=${PV/_beta/b}
S=${WORKDIR}/${PN}-${MY_PV}

DESCRIPTION="HTTP/HTML indexing and searching system"
HOMEPAGE="http://www.htdig.org"
SRC_URI="http://www.htdig.org/files/${PN}-${MY_PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm ~arm64 hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~amd64-linux ~x86-linux"
IUSE="ssl clip clip-deps"

DEPEND="!clip-deps? ( >=sys-libs/zlib-1.1.3 )
	app-arch/unzip
	ssl? ( dev-libs/openssl )"

src_unpack() {
	unpack ${A}

	cd "${S}"
	epatch "${FILESDIR}"/${P}-gcc4.patch
	epatch "${FILESDIR}"/${P}-as-needed.patch
	epatch "${FILESDIR}"/${P}-quoting.patch
	
	# from original file htdig-3.2.0_beta6-r3.buiild
	# sed -e "s/AM_CONFIG_HEADER/AC_CONFIG_HEADERS/" -i configure.in db/configure.in || die
	# eautoreconf
        # from original file htdig-3.2.0_beta6-r3.buiild
}

src_compile() {
	# from original file htdig-3.2.0_beta6-r3.buiild
	# use prefix || EPREFIX=
        # from original file htdig-3.2.0_beta6-r3.buiild
	
	# from htdig-3.1.99_beta6-r5.buiild
	local www_pref="/var/www"
	use clip && www_pref="/var/shared/www"
	
        local conf="
		--with-config-dir=${CPREFIX}/etc/${PN} \
		--with-default-config-file=${CPREFIX}/etc/${PN}/${PN}.conf \	
   		--with-database-dir=/var/lib/${PN}/db \
		--with-cgi-bin-dir=${www_pref}/localhost/cgi-bin \
		--with-search-dir=${www_pref}/localhost/htdocs/${PN} \
		--with-image-dir=${www_pref}/localhost/htdocs/${PN} \
	"
	use ssl && conf="${conf} --with-ssl"
	
	econf ${conf} || die "configure failed"
        # from htdig-3.1.99_beta6-r5.buiild

        # from original file htdig-3.2.0_beta6-r3.buiild
        #	econf \
        #	--with-config-dir="${CPREFIX}"/etc/${PN} \
        #	--with-default-config-file="${CPREFIX}"/etc/${PN}/${PN}.conf \
        #	--with-database-dir=/var/lib/${PN}/db \
        #	--with-cgi-bin-dir="${www_pref}"/var/www/localhost/cgi-bin \
        #	--with-search-dir="${www_pref}"/var/www/localhost/htdocs/${PN} \
        #	--with-image-dir="${www_pref}"/var/www/localhost/htdocs/${PN} \
        #	$(use_with ssl)
        # from original file htdig-3.2.0_beta6-r3.buiild    
        
        #	--with-image-url-prefix="file://${EPREFIX}/var/www/localhost/htdocs/${PN}" \
        
	emake || die "emake failed"
}

src_install () {
	# from original file htdig-3.2.0_beta6-r3.buiild
#	use prefix || ED="${D}"
	# from original file htdig-3.2.0_beta6-r3.buiild
	
	# from htdig-3.1.99_beta6-r5.buiild
	local www_root="/var/www"
	use clip && www_root="/var/shared/www"	
	# from htdig-3.1.99_beta6-r5.buiild
	
	emake DESTDIR="${D}" install || die "make install failed"

	dodoc ChangeLog README
	dohtml -r htdoc

	# from htdig-3.1.99_beta6-r5.buiild
	dosed /etc/${PN}/${PN}.conf
	dosed /usr/bin/rundig	
	# from htdig-3.1.99_beta6-r5.buiild
	
	# from original file htdig-3.2.0_beta6-r3.buiild
        # 	sed -i "s:${D}::g" \
        #   		"${ED}"/etc/${PN}/${PN}.conf \
        # 		"${ED}"/usr/bin/rundig \
        # 		|| die "sed failed (removing \${D} from installed files)"
        # from original file htdig-3.2.0_beta6-r3.buiild

	# symlink htsearch so it can be easily found. see bug #62087
	
	# from htdig-3.1.99_beta6-r5.buiild
	dosym ${www_root}/localhost/cgi-bin/htsearch /usr/bin/htsearch
	# from htdig-3.1.99_beta6-r5.buiild
}
