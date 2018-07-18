# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"

inherit autotools ssl-cert eutils multilib systemd user verictl2

DESCRIPTION="TLS/SSL - Port Wrapper"
HOMEPAGE="http://www.stunnel.org/index.html"
SRC_URI="ftp://ftp.stunnel.org/stunnel/archive/${PV%%.*}.x/${P}.tar.gz
	http://www.usenix.org.uk/mirrors/stunnel/archive/${PV%%.*}.x/${P}.tar.gz
	http://ftp.nluug.nl/pub/networking/stunnel/archive/${PV%%.*}.x/${P}.tar.gz
	http://www.namesdir.com/mirrors/stunnel/archive/${PV%%.*}.x/${P}.tar.gz
	http://stunnel.cybermirror.org/archive/${PV%%.*}.x/${P}.tar.gz
	http://mirrors.zerg.biz/stunnel/archive/${PV%%.*}.x/${P}.tar.gz
	ftp://mirrors.go-parts.com/stunnel/archive/${PV%%.*}.x/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc x86 ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="ipv6 libressl selinux stunnel3 tcpd"
IUSE+=" clip-hermes core-rm clip-core clip clip-gtw clip-rm static"

DEPEND="tcpd? ( sys-apps/tcp-wrappers )
	!libressl? ( dev-libs/openssl:0 )
	libressl? ( dev-libs/libressl )"
RDEPEND="${DEPEND}
	stunnel3? ( dev-lang/perl )
	selinux? ( sec-policy/selinux-stunnel )
	clip-rm? ( app-clip/vaultguard )
	core-rm? ( >=sys-auth/pam_exec_pwd-1.0.3 )"

RESTRICT="test"

pkg_setup() {
	use clip && return 0

	enewgroup stunnel
	enewuser stunnel -1 -1 -1 stunnel
}

src_unpack() {
	use core-rm || default_src_unpack
	# ugly hack, but portage check if this directory exists
	mkdir -p ${S}
}

src_prepare() {
	use core-rm && return 0
	if use clip-hermes && use clip-gtw; then
		epatch "${FILESDIR}/${PN}-hermes-srv-needcrl.patch"
		epatch "${FILESDIR}/${PN}-identprop-0.30-r3.patch"

		epatch "${FILESDIR}/${PN}-4.31-open-log.patch"

		sed -ri "s/^(AM_INIT_AUTOMAKE\(${PN}, ${PV})(\))$/\1-hermes\2/" \
			"${S}/configure.ac" || die "Version replacement failed"
	fi

	epatch "${FILESDIR}/${PN}-pipe-kill.patch"

	eautoreconf

	# Hack away generation of certificate
	sed -i -e "s/^install-data-local:/do-not-run-this:/" \
		tools/Makefile.in || die "sed failed"

	echo "CONFIG_PROTECT=\"/etc/stunnel/stunnel.conf\"" > "${T}"/20stunnel
}

src_configure() {
	use core-rm && return 0
	econf \
		--libdir="${EPREFIX}/${CPREFIX:-/usr}/$(get_libdir)" \
		$(use_enable ipv6) \
		$(use_enable tcpd libwrap) \
		--with-ssl="${EPREFIX}"/${CPREFIX:-/usr} \
		--disable-fips || die "econf died"
}

src_install() {
	if use core-rm; then
		if use !clip-hermes; then
			eerror "Not supported"
			return 1
		fi
		exeinto /sbin
		newexe "${FILESDIR}"/stunnel-killer stunnel-killer

		newinitd "${FILESDIR}"/stunnel.initd_clip stunnel
		for jail in rm_h rm_b; do
			dosym stunnel /etc/init.d/stunnel.${jail}
		done
		insinto /etc/stunnel
		newins "${FILESDIR}"/stunnel.conf.skel_hermes stunnel.conf.skel

		insinto /etc/security/exec.conf.d
		newins "${FILESDIR}"/200-stunnel-killer.conf 200-stunnel-killer.conf
		return 0
	fi

	emake DESTDIR="${D}" install || die "emake install failed"
	rm -rf "${D}${CPREFIX:-/usr}"/share/doc/${PN}
	rm -f "${D}${CPREFIX}"/etc/stunnel/stunnel.conf-sample "${D}${CPREFIX:-/usr}"/bin/stunnel3 \
		"${D}${CPREFIX:-/usr}"/share/man/man8/stunnel.{fr,pl}.8

	use stunnel3 || rm -f "${ED}"/usr/bin/stunnel3

	# The binary was moved to /usr/bin with 4.21,
	# symlink for backwards compatibility
	use clip || dosym ../bin/stunnel /usr/sbin/stunnel

	dodoc AUTHORS BUGS CREDITS PORTS README TODO ChangeLog
	dohtml doc/stunnel.html doc/en/VNC_StunnelHOWTO.html tools/ca.html \
		tools/importCA.html

	if use clip-rm && use clip-hermes; then
		exeinto /bin/clip-user-data-update-scripts
		newexe "${FILESDIR}"/stunnel.autostart stunnel
		rm -r "${D}/etc/stunnel"
		insinto /etc/vault.d
		newins "${FILESDIR}"/vaultguard.conf tls.conf
		# VaultGuard bonus
		fowners 0:6001 /bin/stunnel
		fperms 0710 /bin/stunnel
	fi
	use clip && return 0

	insinto /etc/stunnel
	doins "${FILESDIR}"/stunnel.conf
	newinitd "${FILESDIR}"/stunnel.initd-start-stop-daemon stunnel

	keepdir /var/run/stunnel
	fowners stunnel:stunnel /var/run/stunnel
	doenvd "${T}"/20stunnel
	systemd_dounit "${S}/tools/stunnel.service"
	systemd_newtmpfilesd "${FILESDIR}"/stunnel.tmpfiles.conf stunnel.conf
}

pkg_postinst() {
	if [ ! -f "${EROOT}"/etc/stunnel/stunnel.key ]; then
		install_cert /etc/stunnel/stunnel
		chown stunnel:stunnel "${EROOT}"/etc/stunnel/stunnel.{crt,csr,key,pem}
		chmod 0640 "${EROOT}"/etc/stunnel/stunnel.{crt,csr,key,pem}
	fi

	einfo "If you want to run multiple instances of stunnel, create a new config"
	einfo "file ending with .conf in /etc/stunnel/. **Make sure** you change "
	einfo "\'pid= \' with a unique filename."

}

pkg_predeb() {
	if use clip-core; then
		init_maintainer "postinst"
		cat >> "${D}/DEBIAN/postinst" <<ENDSCRIPT
rc-update add stunnel default
ENDSCRIPT
		init_maintainer "prerm"
		cat >> "${D}/DEBIAN/prerm" <<ENDSCRIPT
rc-update del stunnel default
ENDSCRIPT
	else
		doverictld2 ${CPREFIX:-/usr}/bin/stunnel e NET_BIND_SERVICE NET_BIND_SERVICE NET_BIND_SERVICE csN
	fi
}
