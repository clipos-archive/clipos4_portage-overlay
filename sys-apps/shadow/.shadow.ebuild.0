# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/shadow/shadow-4.1.5.1-r1.ebuild,v 1.16 2014/01/18 04:48:18 vapier Exp $

EAPI=4

inherit eutils libtool toolchain-funcs pam multilib autotools flag-o-matic verictl2

DESCRIPTION="Utilities to deal with user accounts"
HOMEPAGE="http://shadow.pld.org.pl/ http://pkg-shadow.alioth.debian.org/"
SRC_URI="http://pkg-shadow.alioth.debian.org/releases/${P}.tar.bz2"

LICENSE="BSD GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86"
IUSE="acl audit cracklib nls pam selinux skey xattr nousuid clip clip-tcb clip-devstation clip-bare"

RDEPEND="acl? ( sys-apps/acl )
	audit? ( sys-process/audit )
	cracklib? ( >=sys-libs/cracklib-2.7-r3 )
	pam? ( virtual/pam )
	clip-tcb? ( sys-auth/pam_userpass )
	!sys-apps/pam-login
	!app-admin/nologin
	skey? ( sys-auth/skey )
	selinux? (
		>=sys-libs/libselinux-1.28
		sys-libs/libsemanage
	)
	nls? ( virtual/libintl )
	xattr? ( sys-apps/attr )
	clip? ( sys-auth/pam_pkcs11 )
	clip-bare? ( sys-auth/pam_jail )"
DEPEND="${RDEPEND}
	nls? ( sys-devel/gettext )
	clip-tcb? ( sys-apps/tcb )"
RDEPEND="${RDEPEND}
	!clip-devstation? ( !clip? ( pam? ( >=sys-auth/pambase-20120417 ) ) )"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-4.1.3-dots-in-usernames.patch #22920
	epatch_user

	if use clip-tcb; then
		epatch "${FILESDIR}"/${P}-avx-owl-crypt_gensalt.patch
		epatch "${FILESDIR}"/${P}-avx-owl-tcb.patch
		epatch "${FILESDIR}"/${P}-avx-owl-usergroupname_max.patch
		epatch "${FILESDIR}"/${P}-makefile-ldflags-and-bad-directive.patch
	fi
	if use clip; then
		epatch "${FILESDIR}"/${P}-clip-nofollow.patch
	fi
	if use clip-bare; then
		epatch "${FILESDIR}"/${P}-pam_jail-login.patch
	fi

	epatch "${FILESDIR}"/${P}-stdbool.patch

	# added because of patches applied above
	eautoreconf -i

	elibtoolize
}

src_configure() {
	tc-is-cross-compiler && export ac_cv_func_setpgrp_void=yes
	econf \
		$(use_with clip-tcb tcb) \
		--without-group-name-max-length \
		--enable-shared=no \
		--enable-static=yes \
		$(use_with acl) \
		$(use_with audit) \
		$(use_with cracklib libcrack) \
		$(use_with pam libpam) \
		$(use_with skey) \
		$(use_with selinux) \
		$(use_enable nls) \
		$(use_with elibc_glibc nscd) \
		$(use_with xattr attr)
	has_version 'sys-libs/uclibc[-rpc]' && sed -i '/RLOGIN/d' config.h #425052
}

set_login_opt() {
	local comment="" opt=$1 val=$2
	[[ -z ${val} ]] && comment="#"
	sed -i -r \
		-e "/^#?${opt}/s:.*:${comment}${opt} ${val}:" \
		"${D}"/etc/login.defs
	local res=$(grep "^${comment}${opt}" "${D}"/etc/login.defs)
	einfo ${res:-Unable to find ${opt} in /etc/login.defs}
}

src_install() {
	local perms=4711
	use nousuid && perms=711
	emake DESTDIR="${D}" suidperms=${perms} install || die "install problem"

	# Remove libshadow and libmisc; see bug 37725 and the following
	# comment from shadow's README.linux:
	#   Currently, libshadow.a is for internal use only, so if you see
	#   -lshadow in a Makefile of some other package, it is safe to
	#   remove it.
	rm -f "${D}"/{,usr/}$(get_libdir)/lib{misc,shadow}.{a,la}

	insinto /etc
	# Using a securetty with devfs device names added
	# (compat names kept for non-devfs compatibility)
	insopts -m0600 ; doins "${FILESDIR}"/securetty
	if ! use pam ; then
		insopts -m0600
		doins etc/login.access etc/limits
	fi
	# Output arch-specific cruft
	local devs
	case $(tc-arch) in
		ppc*)  devs="hvc0 hvsi0 ttyPSC0";;
		hppa)  devs="ttyB0";;
		arm)   devs="ttyFB0 ttySAC0 ttySAC1 ttySAC2 ttySAC3 ttymxc0 ttymxc1 ttymxc2 ttymxc3 ttyO0 ttyO1 ttyO2";;
		sh)    devs="ttySC0 ttySC1";;
	esac
	[[ -n ${devs} ]] && printf '%s\n' ${devs} >> "${D}"/etc/securetty

	# needed for 'useradd -D'
	insinto /etc/default
	insopts -m0600
	if use clip; then
		newins "${FILESDIR}"/default/useradd.clip useradd
	else 
		doins "${FILESDIR}"/default/useradd
	fi

	# move passwd to / to help recover broke systems #64441
	mv "${D}"/usr/bin/passwd "${D}"/bin/
	dosym /bin/passwd /usr/bin/passwd

	if use pam ; then
		if use clip; then
			rm -f "${D}/etc/pam.d"/*
			for x in chage chsh chfn su\
					 user{add,del,mod} group{add,del,mod} ; do
				newpamd "${FILESDIR}"/pam.d.clip/shadow ${x}
			done

			for x in other login passwd shadow system-auth xdm ; do
				newpamd "${FILESDIR}"/pam.d.clip/${x} ${x}
			done
			newpamd "${FILESDIR}"/pam.d.clip/xdm slim
			
			# CLIP : adding pam_jail module as a session requirement on
			# clip-bare distribution
			use clip-bare || sed -i -e '/@clip-bare_pam-jail@/d' "${D}"/etc/pam.d/login
			use clip-bare && sed -i -e 's:@clip-bare_pam-jail@::g' "${D}"/etc/pam.d/login
			use clip-bare || sed -i -e '/@clip-bare_pam-exec-pwd@/d' "${D}"/etc/pam.d/login
			use clip-bare && sed -i -e 's:@clip-bare_pam-exec-pwd@::g' "${D}"/etc/pam.d/login

		else # ! use clip
		
			local INSTALL_SYSTEM_PAMD="yes"

			# Do not install below pam.d files if we have pam-0.78 or later
			has_version '>=sys-libs/pam-0.78' && INSTALL_SYSTEM_PAMD="no"

			for x in "${FILESDIR}"/pam.d-include/*; do
				case "${x##*/}" in
					"login")
						# We do no longer install this one, as its from
						# pam-login now.
						;;
					"system-auth"|"system-auth-1.1"|"other")
						# These we only install if we do not have pam-0.78
						# or later.
						[ "${INSTALL_SYSTEM_PAMD}" = "yes" ] && [ -f ${x} ] && \
							dopamd ${x}
						;;
					"su")
						# Disable support for pam_env and pam_wheel on openpam
						has_version sys-libs/pam && dopamd ${x}
						;;
					"su-openpam")
						has_version sys-libs/openpam && newpamd ${x} su
						;;
					*)
						[ -f ${x} ] && dopamd ${x}
						;;
				esac
			done
			for x in chage chsh chfn chpasswd newusers \
					 user{add,del,mod} group{add,del,mod} ; do
				newpamd "${FILESDIR}"/pam.d-include/shadow ${x}
			done

			# remove manpages that pam will install for us
			# and/or don't apply when using pam

			find "${D}"/usr/share/man \
				'(' -name 'limits.5*' -o -name 'suauth.5*' ')' \
				-exec rm {} \;
		fi # ! use clip 
	fi

	cd "${S}"
	insinto /etc
	insopts -m0644
	if use clip-tcb; then
		newins "${FILESDIR}/login.defs.tcb" login.defs
	else
		newins etc/login.defs login.defs
	fi

	if ! use pam ; then
		set_login_opt MAIL_CHECK_ENAB no
		set_login_opt SU_WHEEL_ONLY yes
		set_login_opt CRACKLIB_DICTPATH ${CPREFIX:-/usr}/$(get_libdir)/cracklib_dict
		set_login_opt LOGIN_RETRIES 3
		set_login_opt ENCRYPT_METHOD SHA512
	else
		if use !clip-tcb; then
			# comment out login.defs options that pam hates
			local opt
			for opt in \
				CHFN_AUTH \
				CRACKLIB_DICTPATH \
				ENV_HZ \
				ENVIRON_FILE \
				FAILLOG_ENAB \
				FTMP_FILE \
				LASTLOG_ENAB \
				MAIL_CHECK_ENAB \
				MOTD_FILE \
				NOLOGINS_FILE \
				OBSCURE_CHECKS_ENAB \
				PASS_ALWAYS_WARN \
				PASS_CHANGE_TRIES \
				PASS_MIN_LEN \
				PORTTIME_CHECKS_ENAB \
				QUOTAS_ENAB \
				SU_WHEEL_ONLY
			do
				set_login_opt ${opt}
			done
		fi
	
		if use !clip-tcb || use clip-devstation; then
			sed -i -f "${FILESDIR}"/login_defs_pam.sed \
				"${D}"/etc/login.defs

			# remove manpages that pam will install for us
			# and/or don't apply when using pam
			find "${D}"/usr/share/man \
				'(' -name 'limits.5*' -o -name 'suauth.5*' ')' \
				-exec rm {} +

			# Remove pam.d files provided by pambase.
			rm "${D}"/etc/pam.d/{login,passwd,su} || die
		fi
	fi

	if use clip-bare; then
		echo "FAKE_SHELL	/bin/login.tty" >> "${D}"/etc/login.defs
	fi

	# Remove manpages that are handled by other packages
	find "${D}"/usr/share/man \
		'(' -name id.1 -o -name passwd.5 -o -name getspnam.3 ')' \
		-exec rm {} +

	cd "${S}"
	dodoc ChangeLog NEWS TODO
	newdoc README README.download
	cd doc
	dodoc HOWTO README* WISHLIST *.txt

	if use clip-tcb ; then
		fowners root:shadow /bin/passwd
		fowners root:shadow /usr/bin/chage
		fperms 2711 /usr/bin/chage
		fperms 2711 /bin/passwd
		fperms 711 /bin/su
	fi
	if use nousuid ; then
		find "${D}" -perm -u+s -exec chmod u-s '{}' \;
	fi
	if use clip; then
		insinto /etc
		newins "${FILESDIR}"/securetty.clip securetty
	fi
}

pkg_preinst() {
	rm -f "${ROOT}"/etc/pam.d/system-auth.new \
		"${ROOT}/etc/login.defs.new"
}

pkg_postinst() {
	# Enable shadow groups.
	if [ ! -f "${ROOT}"/etc/gshadow ] ; then
		if grpck -r -R "${ROOT}" 2>/dev/null ; then
			grpconv -R "${ROOT}"
		else
			ewarn "Running 'grpck' returned errors.  Please run it by hand, and then"
			ewarn "run 'grpconv' afterwards!"
		fi
	fi

	einfo "The 'adduser' symlink to 'useradd' has been dropped."
}

pkg_predeb () {
	if use clip-bare; then
		doverictld2 /bin/login Ier \
                	'CONTEXT|SYS_TTY_CONFIG|MKNOD|SYS_CHROOT|SYS_ADMIN' \
	                'CONTEXT|SYS_CHROOT|SYS_ADMIN' \
	                'CONTEXT|SYS_TTY_CONFIG|MKNOD|SYS_CHROOT|SYS_ADMIN' \
	                r
	fi
}

