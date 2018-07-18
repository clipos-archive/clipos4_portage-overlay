# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# See `man savedconfig.eclass` for info on how to use USE=savedconfig.

EAPI="5"
inherit eutils flag-o-matic savedconfig toolchain-funcs multilib
inherit verictl2 deb

DESCRIPTION="Utilities for rescue and embedded systems"
HOMEPAGE="https://www.busybox.net/"
if [[ ${PV} == "9999" ]] ; then
	MY_P=${PN}
	EGIT_REPO_URI="git://busybox.net/busybox.git"
	inherit git-2
else
	MY_P=${PN}-${PV/_/-}
	SRC_URI="https://www.busybox.net/downloads/${MY_P}.tar.bz2"
	KEYWORDS="alpha amd64 arm arm64 hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
fi

LICENSE="GPL-2" # GPL-2 only
SLOT="0"
IUSE="debug ipv6 livecd make-symlinks math mdev -pam selinux sep-usr +static syslog systemd"
IUSE="${IUSE} clip-core clip-devel clip-livecd clip rm-core core-deps clip-devstation"
RESTRICT="test"

COMMON_DEPEND="!static? ( selinux? ( sys-libs/libselinux ) )
	clip? ( rm-core? ( >=clip-layout/baselayout-update-1.1.0-r5 ) )
	!core-deps? ( pam? ( sys-libs/pam ) )"
DEPEND="${COMMON_DEPEND}
	clip? ( sys-kernel/clip-kernel )
	clip-devstation? ( sys-kernel/clip-kernel )
	static? ( selinux? ( sys-libs/libselinux[static-libs(+)] ) )
	clip-devstation? ( ~sys-kernel/linux-headers-4.4 )
	clip-livecd? ( ~sys-kernel/linux-headers-4.4 )
	>=sys-kernel/linux-headers-2.6.39"
RDEPEND="${COMMON_DEPEND}
mdev? ( !<sys-apps/openrc-0.13 )"

S=${WORKDIR}/${MY_P}

busybox_config_option() {
	local flag=$1 ; shift
	if [[ ${flag} != [yn] ]] ; then
		busybox_config_option $(usex ${flag} y n) "$@"
		return
	fi
	while [[ $# -gt 0 ]] ; do
		if [[ ${flag} == "y" ]] ; then
			sed -i -e "s:.*\<CONFIG_$1\>.*set:CONFIG_$1=y:g" .config
		else
			sed -i -e "s:CONFIG_$1=y:# CONFIG_$1 is not set:g" .config
		fi
		einfo $(grep "CONFIG_$1[= ]" .config || echo Could not find CONFIG_$1 ...)
		shift
	done
}

busybox_config_enabled() {
	local val=$(sed -n "/^CONFIG_$1=/s:^[^=]*=::p" .config)
	case ${val} in
	"") return 1 ;;
	y)  return 0 ;;
	*)  echo "${val}" | sed -r 's:^"(.*)"$:\1:' ;;
	esac
}

busybox_clip_config() {

	if [[ -z "${DEB_NAME_SUFFIX}" ]]; then
		if use clip-livecd; then
			cp "${FILESDIR}/config-${PV}/config-livecd" "${S}/.config" \
				|| die "Failed to copy livecd config"
		else
			make allyesconfig > /dev/null
		fi
	else

		local conf=""
		case "${DEB_NAME_SUFFIX}" in 
			-admin|-audit|-user|-update|-rm|-viewer|-initrd)
				conf="${FILESDIR}/config-${PV}/config${DEB_NAME_SUFFIX}"
				einfo "Using ${DEB_NAME_SUFFIX#-} config"
				;;
			*)
				die "Unsuported DEB_NAME_SUFFIX: ${DEB_NAME_SUFFIX}"
				;;
		esac

		if use clip-devel && test -e "${conf}-devel"; then
			einfo "Using devel profile"
			conf="${conf}-devel}"
		fi

		cp  "${conf}" "${S}/.config" || die "failed to copy ${conf} as config"

		if [[ "x${DEB_NAME_SUFFIX}" == "x-update" ]] && use clip-core; then
			busybox_config_option y GUNZIP
			busybox_config_option y GZIP
			busybox_config_option y BUNZIP2
		fi

		# make sure the shell is usable interactively when clip-devel is set
		if use clip-devel; then
			busybox_config_option y FEATURE_EDITING
			busybox_config_option y FEATURE_TAB_COMPLETION
			busybox_config_option y FEATURE_EDITING_SAVEHISTORY
		fi
	fi

	# some safe values
	busybox_config_option n DMALLOC
	busybox_config_option n FEATURE_SUID_CONFIG
	busybox_config_option n BUILD_AT_ONCE
	busybox_config_option n BUILD_LIBBUSYBOX

	busybox_config_option n MONOTONIC_SYSCALL

	# If these are not set and we are using a uclibc/busybox setup
	# all calls to system() will fail.
	busybox_config_option y ASH
	busybox_config_option n HUSH

	# Safeguard for the unfixed CVE-2011-5325, cf. #3400
	busybox_config_option n TAR

	# disable ipv6 applets
	if ! use ipv6; then
		busybox_config_option n FEATURE_IPV6
		busybox_config_option n TRACEROUTE6
		busybox_config_option n PING6
	fi

	if use static && use pam ; then
		ewarn "You cannot have USE='static pam'.  Assuming static is more important."
	fi
	use static \
		&& busybox_config_option n PAM \
		|| busybox_config_option pam PAM

	busybox_config_option static STATIC
	busybox_config_option debug DEBUG
	use debug \
		&& busybox_config_option y NO_DEBUG_LIB \
		&& busybox_config_option n DMALLOC \
		&& busybox_config_option n EFENCE

	busybox_config_option selinux SELINUX

	make silentoldconfig 
}

src_prepare() {
	unset KBUILD_OUTPUT #88088
	append-flags -fno-strict-aliasing #310413
	use ppc64 && append-flags -mminimal-toc #130943

	# patches go here!
	epatch "${FILESDIR}"/${PN}-1.19.0-bb.patch
#	epatch "${FILESDIR}"/${P}-*.patch
	cp "${FILESDIR}"/ginit.c init/ || die

	# flag cleanup
	sed -i -r \
		-e 's:[[:space:]]?-(Werror|Os|falign-(functions|jumps|loops|labels)=1|fomit-frame-pointer)\>::g' \
		Makefile.flags || die
	#sed -i '/bbsh/s:^//::' include/applets.h
	sed -i '/^#error Aborting compilation./d' applets/applets.c || die
	use elibc_glibc && sed -i 's:-Wl,--gc-sections::' Makefile
	sed -i \
		-e "/^CROSS_COMPILE/s:=.*:= ${CHOST}-:" \
		-e "/^AR\>/s:=.*:= $(tc-getAR):" \
		-e "/^CC\>/s:=.*:= $(tc-getCC):" \
		-e "/^HOSTCC/s:=.*:= $(tc-getBUILD_CC):" \
		-e "/^PKG_CONFIG\>/s:=.*:= $(tc-getPKG_CONFIG):" \
		Makefile || die
	sed -i \
		-e 's:-static-libgcc::' \
		Makefile.flags || die

	if use clip || use clip-livecd; then 
		epatch "${FILESDIR}"/${PN}-1.17.1-clip-switch_root.patch
		[[ "${DEB_NAME_SUFFIX}" != "-user" ]] && \
			epatch "${FILESDIR}"/${PN}-clip-1.22.1-ls-infinite-loop.patch
	fi
	if use clip; then
		epatch "${FILESDIR}"/${PN}-clip-1.18.4-mayexec.patch
		epatch "${FILESDIR}"/${PN}-1.15.1-dpkg_clip.patch  # OK
		epatch "${FILESDIR}"/${PN}-1.23.0-clip-crontab.patch # OK
		epatch "${FILESDIR}"/${PN}-1.23.0-clip-df.patch
		epatch "${FILESDIR}"/${PN}-1.23.0-clip-top.patch
	fi
}

src_configure() {
	if use clip || use clip-livecd; then
		busybox_clip_config || die "Failed to configure"
	else
		# check for a busybox config before making one of our own.
		# if one exist lets return and use it.

		restore_config .config
		if [ -f .config ]; then
			yes "" | emake -j1 -s oldconfig >/dev/null
			return 0
		else
			ewarn "Could not locate user configfile, so we will save a default one"
		fi

		# setup the config file
		emake -j1 -s allyesconfig >/dev/null
		# nommu forces a bunch of things off which we want on #387555
		busybox_config_option n NOMMU
		sed -i '/^#/d' .config
		yes "" | emake -j1 -s oldconfig >/dev/null

		# now turn off stuff we really don't want
		busybox_config_option n DMALLOC
		busybox_config_option n FEATURE_SUID_CONFIG
		busybox_config_option n BUILD_AT_ONCE
		busybox_config_option n BUILD_LIBBUSYBOX
		busybox_config_option n FEATURE_CLEAN_UP
		busybox_config_option n MONOTONIC_SYSCALL
		busybox_config_option n USE_PORTABLE_CODE
		busybox_config_option n WERROR
		# triming the BSS size may be dangerous
		busybox_config_option n FEATURE_USE_BSS_TAIL

		# If these are not set and we are using a uclibc/busybox setup
		# all calls to system() will fail.
		busybox_config_option y ASH
		busybox_config_option n HUSH

		# disable ipv6 applets
		if ! use ipv6; then
			busybox_config_option n FEATURE_IPV6
			busybox_config_option n TRACEROUTE6
			busybox_config_option n PING6
			busybox_config_option n UDHCPC6
		fi

		busybox_config_option pam PAM
		busybox_config_option static STATIC
		busybox_config_option syslog {K,SYS}LOGD LOGGER
		busybox_config_option systemd FEATURE_SYSTEMD
		busybox_config_option math FEATURE_AWK_LIBM

		# all the debug options are compiler related, so punt them
		busybox_config_option n DEBUG_SANITIZE
		busybox_config_option n DEBUG
		busybox_config_option y NO_DEBUG_LIB
		busybox_config_option n DMALLOC
		busybox_config_option n EFENCE
		busybox_config_option $(usex debug y n) TFTP_DEBUG

		busybox_config_option selinux SELINUX

		# this opt only controls mounting with <linux-2.6.23
		busybox_config_option n FEATURE_MOUNT_NFS

		# default a bunch of uncommon options to off
		local opt
		for opt in \
			ADD_SHELL \
			BEEP BOOTCHARTD \
			CRONTAB \
			DC DEVFSD DNSD DPKG{,_DEB} \
			FAKEIDENTD FBSPLASH FOLD FSCK_MINIX FTP{GET,PUT} \
			FEATURE_DEVFS \
			HOSTID HUSH \
			INETD INOTIFYD IPCALC \
			LOCALE_SUPPORT LOGNAME LPD \
			MAKEMIME MKFS_MINIX MSH \
			OD \
			RDEV READPROFILE REFORMIME REMOVE_SHELL RFKILL RUN_PARTS RUNSV{,DIR} \
			SLATTACH SMEMCAP SULOGIN SV{,LOGD} \
			TASKSET TCPSVD \
			RPM RPM2CPIO \
			UDPSVD UUDECODE UUENCODE
		do
			busybox_config_option n ${opt}
		done

		emake -j1 oldconfig > /dev/null
	fi
}

src_compile() {
	unset KBUILD_OUTPUT #88088
	export SKIP_STRIP=y

	emake V=1 busybox
}

src_install() {
	unset KBUILD_OUTPUT #88088
	use clip || save_config .config

	into /

	dodir /bin
	if [[ "${DEB_NAME_SUFFIX}" == "-initrd" ]]; then
		exeinto /bin
		newexe "${S}/busybox" "initrd-sh"
	elif use sep-usr ; then
		# install /ginit to take care of mounting stuff
		exeinto /
		newexe busybox_unstripped ginit
		dosym /ginit /bin/bb
		dosym bb /bin/busybox
	elif use clip-livecd; then
		newbin busybox_unstripped busybox-livecd
	else
		newbin busybox_unstripped busybox
		dosym busybox /bin/bb
	fi

	if [[ "${DEB_NAME_SUFFIX}" == "-update" ]] ; then
		exeinto /bin
		doexe "${FILESDIR}/cleanup_log.sh"
	fi

	if [[ "${DEB_NAME_SUFFIX}" == "-admin" || "${DEB_NAME_SUFFIX}" == "-audit" ]] ; then
		exeinto /bin
		doexe "${FILESDIR}/login_shell.sh"
	fi

	if use mdev ; then
		dodir /$(get_libdir)/mdev/
		use make-symlinks || dosym /bin/bb /sbin/mdev
		cp "${S}"/examples/mdev_fat.conf "${ED}"/etc/mdev.conf

		exeinto /$(get_libdir)/mdev/
		doexe "${FILESDIR}"/mdev/*

		newinitd "${FILESDIR}"/mdev.initd mdev
	fi
	if use livecd ; then
		dosym busybox /bin/vi
	fi

	# add busybox daemon's, bug #444718
	if busybox_config_enabled FEATURE_NTPD_SERVER; then
		newconfd "${FILESDIR}/ntpd.confd" "busybox-ntpd"
		newinitd "${FILESDIR}/ntpd.initd" "busybox-ntpd"
	fi
	if busybox_config_enabled SYSLOGD; then
		newconfd "${FILESDIR}/syslogd.confd" "busybox-syslogd"
		newinitd "${FILESDIR}/syslogd.initd" "busybox-syslogd"
	fi
	if busybox_config_enabled KLOGD; then
		newconfd "${FILESDIR}/klogd.confd" "busybox-klogd"
		newinitd "${FILESDIR}/klogd.initd" "busybox-klogd"
	fi
	if busybox_config_enabled WATCHDOG; then
		newconfd "${FILESDIR}/watchdog.confd" "busybox-watchdog"
		newinitd "${FILESDIR}/watchdog.initd" "busybox-watchdog"
	fi
	if busybox_config_enabled UDHCPC; then
		local path=$(busybox_config_enabled UDHCPC_DEFAULT_SCRIPT)
		exeinto "${path%/*}"
		newexe examples/udhcp/simple.script "${path##*/}"
	fi
	if busybox_config_enabled UDHCPD; then
		insinto /etc
		doins examples/udhcp/udhcpd.conf
	fi

	# bundle up the symlink files for use later
	emake DESTDIR="${ED}" install
	rm _install/bin/busybox
	# for compatibility, provide /usr/bin/env
	mkdir -p _install/usr/bin
	ln -s /bin/env _install/usr/bin/env
	if use clip; then
		use make-symlinks && cp -a _install/* "${ED}"
		if [[ "${DEB_NAME_SUFFIX}" == "-initrd" ]]; then
			rm -fr "${ED}/etc"
		fi
	else
		tar cf busybox-links.tar -C _install . || : #;die
		insinto /usr/share/${PN}
		use make-symlinks && doins busybox-links.tar
	fi
	dodoc AUTHORS README TODO

	cd docs
	docinto txt
	dodoc *.txt
	docinto pod
	dodoc *.pod
	dohtml *.html

	cd ../examples
	docinto examples
	dodoc inittab depmod.pl *.conf *.script undeb unrpm

	if [[ "${DEB_NAME_SUFFIX}" == "-update" ]] ; then
		# cron gid is 16 on target installs.
		diropts -m0750 -o root -g 16; dodir /etc/cron/crontab
	fi
	# CLIP? rm -fr "${ED}"/usr/share
	# CLIP? rm -fr "${ED}"/etc/portage

	if [[ "${DEB_NAME_SUFFIX}" == "-initrd" ]] ; then
		rm -fr "${ED}/usr"
		insinto /usr/share/initrd
		doins "${FILESDIR}/fr.kmap"
	fi
}

pkg_preinst() {
	if use make-symlinks && [[ ! ${VERY_BRAVE_OR_VERY_DUMB} == "yes" ]] && [[ ${ROOT} == "/" ]] ; then
		ewarn "setting USE=make-symlinks and emerging to / is very dangerous."
		ewarn "it WILL overwrite lots of system programs like: ls bash awk grep (bug 60805 for full list)."
		ewarn "If you are creating a binary only and not merging this is probably ok."
		ewarn "set env VERY_BRAVE_OR_VERY_DUMB=yes if this is really what you want."
		die "silly options will destroy your system"
	fi

	if use make-symlinks ; then
		mv "${ED}"/usr/share/${PN}/busybox-links.tar "${T}"/ || die
	fi
}

pkg_postinst() {
	savedconfig_pkg_postinst

	if use make-symlinks ; then
		cd "${T}" || die
		mkdir _install
		tar xf busybox-links.tar -C _install || die
		cp -vpPR _install/* "${ROOT}"/ || die "copying links for ${x} failed"
	fi

	if use sep-usr ; then
		elog "In order to use the sep-usr support, you have to update your"
		elog "kernel command line.  Add the option:"
		elog "     init=/ginit"
		elog "To launch a different init than /sbin/init, use:"
		elog "     init=/ginit /sbin/yourinit"
		elog "To get a rescue shell, you may boot with:"
		elog "     init=/ginit bb"
	fi
}

pkg_predeb() {
	[[ "${DEB_NAME_SUFFIX}" == "-rm" ]] || return 0

	init_maintainer "postinst"

	cat >> "${ED}/DEBIAN/postinst" <<EOF
if [[ -f "/etc/conf.d/clip" ]]; then
	source "/etc/conf.d/clip"
else if [[ -f "/etc/conf.d/.clip.confnew" ]]; then
	source "/etc/conf.d/.clip.confnew"
fi
fi

	echo "\${CLIP_JAILS}" | grep -q "rm_h" || sed -i -e '/.*rm_h.*/d' "/etc/verictl.d/busybox-rm"
	echo "\${CLIP_JAILS}" | grep -q "rm_b" || sed -i -e '/.*rm_b.*/d' "/etc/verictl.d/busybox-rm"

EOF
	# keep a reference binary in clip core (read-only)
	mkdir -p "${D}/sbin"
	cp -a "${D}/vservers/rm_h/bin/busybox" "${D}/sbin/busybox-rm"

	VERIEXEC_CTX=1001 doverictld2 /vservers/rm_h/bin/busybox e - - - P 
	VERIEXEC_CTX=1002 doverictld2 /vservers/rm_b/bin/busybox e - - - P 
}
