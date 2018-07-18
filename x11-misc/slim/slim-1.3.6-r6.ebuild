# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/slim/slim-1.3.6-r3.ebuild,v 1.2 2013/10/28 01:31:51 axs Exp $

EAPI=5

CMAKE_MIN_VERSION="2.8.8"
inherit cmake-utils pam eutils systemd versionator verictl2

DESCRIPTION="Simple Login Manager"
HOMEPAGE="http://slim.berlios.de"
SRC_URI="mirror://berlios/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~arm ~mips ~ppc ~ppc64 ~sparc x86 ~x86-fbsd"
IUSE="branding pam consolekit clip core-deps"
REQUIRED_USE="consolekit? ( pam )"

RDEPEND="x11-libs/libXmu
	x11-libs/libX11
	x11-libs/libXpm
	x11-libs/libXft
	!core-deps? ( 
		sys-kernel/clip-kernel
		media-libs/libpng:0=
		virtual/jpeg:=
		pam? (	virtual/pam )
	)
	x11-apps/sessreg
	consolekit? ( sys-auth/consolekit
		sys-apps/dbus )
	pam? ( !x11-misc/slimlock )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	x11-proto/xproto"
PDEPEND="branding? ( >=x11-themes/slim-themes-1.2.3a-r3 )"

src_prepare() {
	# Our Gentoo-specific config changes
	epatch "${FILESDIR}"/${P}-config.diff
	epatch "${FILESDIR}"/${PN}-1.3.5-arm.patch
	epatch "${FILESDIR}"/${P}-honour-cflags.patch
	epatch "${FILESDIR}"/${P}-libslim-cmake-fixes.patch
	epatch "${FILESDIR}"/${PN}-1.3.5-disable-ck-for-systemd.patch
	epatch "${FILESDIR}"/${P}-strip-systemd-unit-install.patch
	epatch "${FILESDIR}"/${P}-systemd-session.patch
	epatch "${FILESDIR}"/${P}-session-chooser.patch
	epatch "${FILESDIR}"/${P}-fix-slimlock-nopam.patch

	if use elibc_FreeBSD; then
		sed -i -e 's/"-DHAVE_SHADOW"/"-DNEEDS_BASENAME"/' CMakeLists.txt \
			|| die
	fi

	if use branding; then
		sed -i -e 's/  default/  slim-gentoo-simple/' slim.conf || die
	fi

	use clip && epatch "${FILESDIR}/slim-1.3.6-clip.patch"
	use clip && epatch "${FILESDIR}/slim-1.3.6-clip-geometry.patch"
}

src_configure() {
	mycmakeargs=(
		$(cmake-utils_use clip WITH_CLIP)
		$(cmake-utils_use pam USE_PAM)
		$(cmake-utils_use consolekit USE_CONSOLEKIT)
	)

	cmake-utils_src_configure
}

src_compile() {
	cmake-utils_src_compile

	local prefix="${CPREFIX:-/usr}"

	if use clip; then
		local bin
		local extra=""
		for bin in rebooter screen-monitor netchoose; do
			gcc -DPREFIX=\"${prefix}\" -o "${T}/${bin}" "${FILESDIR}/${bin}.c" \
				${CFLAGS} $(pkg-config --cflags gtk+-2.0) $(pkg-config --libs gtk+-2.0) ${LDFLAGS} \
				|| die "gcc ${bin}.c failed"
		done
	fi
}

src_install() {
	cmake-utils_src_install

	if use pam ; then
		if ! use clip; then
			pamd_mimic system-local-login slim auth account session
			pamd_mimic system-local-login slimlock auth
		fi
	fi

	if use clip; then
		exeinto /usr/bin
		doexe "${FILESDIR}"/GiveConsole "${FILESDIR}"/TakeConsole "${FILESDIR}"/Xsetup
		local bin
		local extra=""
		for bin in rebooter screen-monitor netchoose; do
			doexe "${T}/${bin}"
		done
		doexe "${FILESDIR}"/screen-size-changed.sh
		newexe "${FILESDIR}"/nonetwork.sh nonetwork
		insinto /usr/share/slim/themes/clip
		doins "${FILESDIR}/clip"/*
		insinto /etc
		newins "${FILESDIR}/slim.conf.clip" slim.conf || die "doins failed"
		for g in 16x8 16x9 16x10 16x11 16x12; do
			dosym "/usr/share/wallpapers/splash-${g}.png" \
					"/usr/share/slim/themes/clip/background-${g}.png"
		done
		for g in 1024x600 1024x768 1152x864 1280x1024 1280x720 1280x800 1280x960 1366x768 1400x1050 1440x1080 1440x900 1600x1200 1600x900 1680x1050 1920x1080 800x600; do
			ln -s "/etc/splash/clip/images/splash-${g}.png" \
					"${D}/${CPREFIX:-/usr}/share/slim/themes/clip/background-${g}.png"
		done
	else
		systemd_dounit slim.service

		insinto /usr/share/slim
		newins "${FILESDIR}/Xsession-r3" Xsession

		insinto /etc/logrotate.d
		newins "${FILESDIR}/slim.logrotate" slim
	fi

	dodoc xinitrc.sample ChangeLog README TODO THEMES
}

pkg_postinst() {
	# note, $REPLACING_VERSIONS will always contain 0 or 1 PV's for slim
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog
		elog "The configuration file is located at /etc/slim.conf."
		elog
		elog "If you wish ${PN} to start automatically, set DISPLAYMANAGER=\"${PN}\" "
		elog "in /etc/conf.d/xdm and run \"rc-update add xdm default\"."
	fi
	if ! version_is_at_least "1.3.2-r7" "${REPLACING_VERSIONS:-1.0}" ; then
		elog
		elog "By default, ${PN} is set up to do proper X session selection, including ~/.xsession"
		elog "support, as well as selection between sessions available in"
		elog "/etc/X11/Sessions/ at login by pressing [F1]."
		elog
		elog "The XSESSION environment variable is still supported as a default"
		elog "if no session has been specified by the user."
		elog
		elog "If you want to use .xinitrc in the user's home directory for session"
		elog "management instead, see README and xinitrc.sample in"
		elog "/usr/share/doc/${PF} and change your login_cmd in /etc/slim.conf"
		elog "accordingly."
		elog
		ewarn "Please note that slim supports consolekit directly.  Please do not use any "
		ewarn "old work-arounds (including calls to 'ck-launch-session' in xinitrc scripts)"
		ewarn "and enable USE=\"consolekit\" instead."
		ewarn
	fi
	if ! use pam; then
		elog "You have merged ${PN} without USE=\"pam\", this will cause ${PN} to fall back to"
		elog "the console when restarting your window manager. If this is not desired, then"
		elog "please remerge ${PN} with USE=\"pam\""
		elog
	fi
}

pkg_predeb() {
	doverictld2 "${CPREFIX:-/usr}/bin/slim" Ier \
		'CONTEXT|SYS_TTY_CONFIG|MKNOD|SYS_CHROOT|SYS_ADMIN' \
		'CONTEXT|SYS_CHROOT|SYS_ADMIN' \
		'CONTEXT|SYS_TTY_CONFIG|MKNOD|SYS_CHROOT|SYS_ADMIN' \
		r
}
