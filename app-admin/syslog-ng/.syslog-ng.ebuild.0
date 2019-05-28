# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-admin/syslog-ng/syslog-ng-3.4.2.ebuild,v 1.12 2013/11/13 17:29:42 mr_bones_ Exp $

EAPI=5
inherit autotools eutils multilib systemd verictl2

MY_PV=${PV/_/}
DESCRIPTION="syslog replacement with advanced filtering features"
HOMEPAGE="http://www.balabit.com/network-security/syslog-ng"
SRC_URI="http://www.balabit.com/downloads/files/syslog-ng/sources/${MY_PV}/source/syslog-ng_${MY_PV}.tar.gz"

LICENSE="GPL-2+ LGPL-2.1+"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 ~sh sparc x86 ~x86-fbsd"
IUSE="caps dbi geoip ipv6 json mongodb +pcre smtp spoof-source ssl systemd tcpd"
IUSE="${IUSE} clip clip-core clip-rm"
RESTRICT="test"

RDEPEND="
	clip-core? ( >=clip-layout/baselayout-clip-1.10.0 )
	clip-core? ( >=app-clip/core-services-2.9.10 )
	clip-core? ( >=app-clip/clip-libvserver-4 )
	pcre? ( dev-libs/libpcre )
	spoof-source? ( net-libs/libnet:1.1 )
	ssl? ( dev-libs/openssl:= )
	smtp? ( net-libs/libesmtp )
	tcpd? ( >=sys-apps/tcp-wrappers-7.6 )
	>=dev-libs/eventlog-0.2.12
	>=dev-libs/glib-2.10.1:2
	json? ( >=dev-libs/json-c-0.9 )
	caps? ( sys-libs/libcap )
	geoip? ( >=dev-libs/geoip-1.5.0 )
	dbi? ( >=dev-db/libdbi-0.8.3 )
	systemd? ( sys-apps/systemd )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/flex"
PROVIDE="virtual/logger"

S=${WORKDIR}/${PN}-${MY_PV}

pkg_setup() {
	use clip-core && CLIP_CONF_FILES="/mounts/audit_priv/etc.audit/syslog"
}

src_prepare() {
	if use clip; then
		epatch "${FILESDIR}/${PN}-3.4.7-clip.patch"
		use clip-core && epatch "${FILESDIR}/${PN}-3.4.7-clip-jail.patch"
		if use clip-rm; then 
			epatch "${FILESDIR}/${PN}-3.4.7-clip-uuid.patch"
			epatch "${FILESDIR}/${PN}-3.4.7-clip-persistent-path.patch"
		fi
	fi

	eautoreconf
}

src_configure() {
	local myconf=""
	if use clip-rm; then
		myconf="${myconf} 
			--with-module-path=/update/usr/lib/syslog-ng:/usr/lib/syslog-ng
			--disable-uuid"
	fi
	econf \
		--with-ivykis=internal \
		--with-libmongo-client=internal \
		--sysconfdir=/etc/syslog-ng \
		--localstatedir=/var/lib/syslog-ng \
		--with-pidfile-dir=/var/run \
		--with-module-dir=/usr/$(get_libdir)/syslog-ng \
		$(systemd_with_unitdir) \
		$(use_enable systemd) \
		$(use_enable caps linux-caps) \
		$(use_enable geoip) \
		$(use_enable ipv6) \
		$(use_enable json) \
		$(use_enable mongodb) \
		$(use_enable pcre) \
		$(use_enable smtp) \
		$(use_enable spoof-source) \
		$(use_enable dbi sql) \
		$(use_enable ssl) \
		$(use_enable tcpd tcp-wrapper) \
		${myconf}
}

src_install() {
	# -j1 for bug #484470
	emake -j1 DESTDIR="${D}" install

	dodoc AUTHORS NEWS contrib/syslog-ng.conf* contrib/syslog2ng \
		"${FILESDIR}/${PV%.*}/syslog-ng.conf.gentoo.hardened" \
		"${FILESDIR}/syslog-ng.logrotate.hardened" \
		"${FILESDIR}/README.hardened"

	
	if use clip; then
		insinto /etc/syslog-ng
		if use clip-core; then
			newins "${FILESDIR}/syslog-ng.conf.clip" syslog-ng.conf
		elif use clip-rm; then
			# Rename syslog-ng binary in jails so it won't be launched
			# by older init.d scripts (which might hang at boot)
			mv "${D}/usr/sbin/syslog-ng" "${D}/usr/sbin/syslog-rm"
			newins "${FILESDIR}/syslog-ng.conf.rm" syslog-ng.conf
			exeinto /usr/sbin
			doexe "${FILESDIR}/run-syslog"
		fi
	else 
		# Install default configuration
		insinto /etc/syslog-ng
		if use userland_BSD ; then
			newins "${FILESDIR}/${PV%.*}/syslog-ng.conf.gentoo.fbsd" syslog-ng.conf
		else
			newins "${FILESDIR}/${PV%.*}/syslog-ng.conf.gentoo" syslog-ng.conf
		fi

		insinto /etc/logrotate.d
		newins "${FILESDIR}/syslog-ng.logrotate" syslog-ng

		newinitd "${FILESDIR}/${PV%.*}/syslog-ng.rc6" syslog-ng
		newconfd "${FILESDIR}/${PV%.*}/syslog-ng.confd" syslog-ng
	fi

	if use clip-core; then
		# Extra logging configuration required by specific packages
		# can be dropped here
		dodir "/etc/syslog.d"

		# Audit conf files go there 
		dodir "/mounts/audit_priv/etc.audit"
		fowners 5000:5000 "/mounts/audit_priv/etc.audit"
		insopts -o 5000 -g 5000
		insinto "/mounts/audit_priv/etc.audit"
		newins "${FILESDIR}/syslog.clip" "syslog"
	fi

	keepdir /etc/syslog-ng/patterndb.d /var/lib/syslog-ng
	prune_libtool_files --modules
}

pkg_postinst() {
	elog "For detailed documentation please see the upstream website:"
	elog "http://www.balabit.com/sites/default/files/documents/syslog-ng-ose-3.4-guides/en/syslog-ng-ose-v3.4-guide-admin/html/index.html"

	# bug #355257
	if ! has_version app-admin/logrotate ; then
		echo
		elog "It is highly recommended that app-admin/logrotate be emerged to"
		elog "manage the log files.  ${PN} installs a file in /etc/logrotate.d"
		elog "for logrotate to use."
		echo
	fi
}

pkg_predeb() {
	use clip || return 0

	if use clip-core; then
		# CLSM_PRIVS_KSYSLOG + CLSM_PRIVS_KEEPPRIV 
		doverictld2 /usr/sbin/syslog-ng er - - - kKIcsN
	else
		# CAP_SYS_CHROOT
		doverictld2 /usr/sbin/syslog-rm er SYS_CHROOT SYS_CHROOT - -
	fi
}
