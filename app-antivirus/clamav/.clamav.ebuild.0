# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit eutils flag-o-matic user systemd verictl2

DESCRIPTION="Clam Anti-Virus Scanner"
HOMEPAGE="http://www.clamav.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 ~arm hppa ia64 ppc ppc64 sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~sparc-solaris ~x86-solaris"
IUSE="bzip2 clamdtop iconv ipv6 milter metadata-analysis-api selinux static-libs uclibc"
IUSE="${IUSE} clip clip-deps clip-devstation"

CDEPEND="
	!clip-deps? (
		bzip2? ( app-arch/bzip2 )
		clamdtop? ( sys-libs/ncurses )
		iconv? ( virtual/libiconv )
		>=sys-libs/zlib-1.2.2
	)
	metadata-analysis-api? ( dev-libs/json-c )
	milter? ( || ( mail-filter/libmilter mail-mta/sendmail ) )
	dev-libs/libtommath
	dev-libs/openssl:0
	clip? ( sys-deve/libltdl )
	!clip? ( sys-devel/libtool )"
# openssl is now *required* see this link as to why
# http://blog.clamav.net/2014/02/introducing-openssl-as-dependency-to.html
DEPEND="${CDEPEND}
	virtual/pkgconfig"
RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-clamav )"

DOCS=( AUTHORS BUGS ChangeLog FAQ INSTALL NEWS README UPGRADE )

pkg_setup() {
	if use clip-devstation; then
		enewgroup clamav 341
		enewuser clamav 341 -1 /dev/null clamav
	else
		enewgroup clamav
		enewuser clamav -1 -1 /dev/null clamav
	fi
}

src_prepare() {
	use ppc64 && append-flags -mminimal-toc
	use uclibc && export ac_cv_type_error_t=yes
}

src_configure() {
	local dbdir="${EPREFIX}/var/lib/clamav"
	local myconf=""
	if use clip; then
		dbdir=/home/user/.clamav
		myconf="--disable-llvm --disable-clamuko"
	fi

	econf \
		--disable-experimental \
		--disable-fanotify \
		--enable-id-check \
		--with-dbdir=${dbdir} \
		--with-system-tommath \
		--with-zlib="${EPREFIX}"/usr \
		$(use_enable bzip2) \
		$(use_enable clamdtop) \
		$(use_enable ipv6) \
		$(use_enable milter) \
		$(use_enable static-libs static) \
		$(use_with iconv) \
		$(use_with metadata-analysis-api libjson /usr)
		${myconf}
}

src_install() {
	default

	if ! use clip; then
		rm -rf "${ED}"/var/lib/clamav
		newinitd "${FILESDIR}"/clamd.initd-r6 clamd
		newconfd "${FILESDIR}"/clamd.conf-r1 clamd
	
		systemd_dotmpfilesd "${FILESDIR}/tmpfiles.d/clamav.conf"
		systemd_newunit "${FILESDIR}/clamd_at.service" "clamd@.service"
		systemd_dounit "${FILESDIR}/clamd.service"
		systemd_dounit "${FILESDIR}/freshclamd.service"
	
		keepdir /var/lib/clamav
		fowners clamav:clamav /var/lib/clamav
		keepdir /var/log/clamav
		fowners clamav:clamav /var/log/clamav
	
		dodir /etc/logrotate.d
		insinto /etc/logrotate.d
		newins "${FILESDIR}"/clamav.logrotate clamav
	fi

	if use clip; then
		exeinto "/usr/bin"
		doexe "${FILESDIR}/clamscan.sh" "${FILESDIR}/clamupdate.sh" "${FILESDIR}/freshclam-updated"
		domenu "${FILESDIR}/clamupdate.desktop"
		insinto "/usr/etc/kde/share/kde4/services/ServiceMenus"
		doins "${FILESDIR}/clamscan.desktop"
		exeinto "/usr/bin/clip-user-data-update-scripts"
		newexe "${FILESDIR}/clamav.autostart" "clamav"
		insinto "/usr/share/clamav"
		doins "${FILESDIR}/clamd-autostart.desktop"

		insinto /etc
		newins "${FILESDIR}/clamd.conf.clip" "clamd.conf"
		newins "${FILESDIR}/freshclam.conf.clip" "freshclam.conf"
		rm -f "${D}${CPREFIX}"/etc/*.conf.sample
	else
		for i in clamd freshclam clamav-milter
		do
			[[ -f "${D}${CPREFIX}"/etc/"${i}".conf.sample ]] \
				&& mv "${D}${CPREFIX}"/etc/"${i}".conf{.sample,}
		done

		local varrun="/var/run/clamav"
		local varlog="/var/log/clamav"
		local varlib="/var/lib/clamav"

		# Modify /etc/{clamd,freshclam}.conf to be usable out of the box
		sed -i -e "s:^\(Example\):\# \1:" \
			-e "s:.*\(PidFile\) .*:\1 ${varrun}/clamd.pid:" \
			-e "s:.*\(LocalSocket\) .*:\1 ${varrun}/clamd.sock:" \
			-e "s:.*\(User\) .*:\1 clamav:" \
			-e "s:^\#\(LogFile\) .*:\1 ${varlog}/clamd.log:" \
			-e "s:^\#\(LogTime\).*:\1 yes:" \
			-e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
			"${ED}${CPREFIX}"/etc/clamd.conf
		sed -i -e "s:^\(Example\):\# \1:" \
			-e "s:.*\(PidFile\) .*:\1 ${varrun}/freshclam.pid:" \
			-e "s:.*\(DatabaseOwner\) .*:\1 clamav:" \
			-e "s:^\#\(UpdateLogFile\) .*:\1 ${varlog}/freshclam.log:" \
			-e "s:^\#\(NotifyClamd\).*:\1 ${CPREFIX}/etc/clamd.conf:" \
			-e "s:^\#\(ScriptedUpdates\).*:\1 yes:" \
			-e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
			"${ED}${CPREFIX}"/etc/freshclam.conf		

		if use milter ; then
			# MilterSocket one to include ' /' because there is a 2nd line for
			# inet: which we want to leave
			dodoc "${FILESDIR}"/clamav-milter.README.gentoo
			sed -i -e "s:^\(Example\):\# \1:" \
				-e "s:.*\(PidFile\) .*:\1 ${varrun}/clamav-milter.pid:" \
				-e "s+^\#\(ClamdSocket\) .*+\1 unix:${varrun}/clamd.sock+" \
				-e "s:.*\(User\) .*:\1 clamav:" \
				-e "s+^\#\(MilterSocket\) /.*+\1 unix:${varrun}/clamav-milter.sock+" \
				-e "s:^\#\(AllowSupplementaryGroups\).*:\1 yes:" \
				-e "s:^\#\(LogFile\) .*:\1 ${varlog}/clamav-milter.log:" \
				"${ED}${CPREFIX}"/etc/clamav-milter.conf
			cat > "${ED}${CPREFIX}"/etc/conf.d/clamd <<-EOF
				MILTER_NICELEVEL=19
				START_MILTER=no
			EOF

			systemd_newunit "${FILESDIR}/clamav-milter.service-r1" clamav-milter.service
		fi
	fi

	prune_libtool_files --all
}

pkg_postinst() {
	if use milter ; then
		elog "For simple instructions how to setup the clamav-milter read the"
		elog "clamav-milter.README.gentoo in /usr/share/doc/${PF}"
	fi
	if test -z $(find "${ROOT}"var/lib/clamav -maxdepth 1 -name 'main.c*' -print -quit) ; then
		ewarn "You must run freshclam manually to populate the virus database files"
		ewarn "before starting clamav for the first time.\n"
	fi
}

pkg_predeb() {
	doverictld2 "${CPREFIX:-/usr}/bin/freshclam" e - - - c
}
