# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit xorg-2

DESCRIPTION="X Window System initializer"

LICENSE="${LICENSE} GPL-2"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~mips ppc ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~arm-linux ~x86-linux"
IUSE="+minimal systemd clip clip-core clip-livecd"

RDEPEND="
	clip-core? ( 
			>=x11-wm/openbox-3.4.7.2-r6
			>=x11-misc/adeskbar-0.4.3-r9
			>=x11-misc/slim-1.3.1_p20091114-r9
			x11-misc/numlockx
			lxde-base/lxinput
			lxde-base/lxkeymap
			clip-data/clip-wallpapers
			media-gfx/feh
	        >=app-clip/clip-usb-clt-2.1.1
	)
	clip-livecd? (
		clip-dev/clip-install-gui
		>=x11-wm/openbox-3.4.7.2-r6
		>=x11-misc/adeskbar-0.4.3-r24
		clip-data/clip-wallpapers
		media-gfx/feh
	)
	clip? ( !app-clip/clip-menu )
	!<x11-base/xorg-server-1.8.0
	x11-apps/xauth
	x11-libs/libX11
"
DEPEND="${RDEPEND}"
PDEPEND="x11-apps/xrdb
	!clip? ( !minimal? (
		x11-apps/xclock
		x11-apps/xsm
		x11-terms/xterm
		x11-wm/twm
	) )
"

PATCHES=(
	"${FILESDIR}/${PN}-1.3.3-gentoo-customizations.patch"
)

src_prepare() {
	# this patch breaks startx on non-systemd systems, bug #526802
	if use !systemd; then
		PATCHES+=( "${FILESDIR}"/${PN}-1.3.4-startx-current-vt.patch )
	fi
	xorg-2_src_prepare
}

src_configure() {
	XORG_CONFIGURE_OPTIONS=(
		--with-xinitdir=${CPREFIX}/etc/X11/xinit
	)
	xorg-2_src_configure
}

src_install() {
	xorg-2_src_install

	local ext=""
	use clip && ext=".clip"

	exeinto /etc/X11
	use clip || doexe "${FILESDIR}"/chooser.sh
	newexe ${FILESDIR}/startDM.sh${ext} startDM.sh
	
	if use clip; then
		exeinto "/etc/X11/Sessions"
		doexe "${FILESDIR}/CLIP"
		#dosed -i -e "s/CHOST/${CHOST}/g" "/etc/X11/Sessions/CLIP" || die
		exeinto /etc/X11/xinit
		newexe ${FILESDIR}/xinitrc.clip xinitrc
	else
		exeinto "/etc/X11/Sessions"
		doexe "${FILESDIR}/Xsession"
		exeinto /etc/X11/xinit
		newexe "${FILESDIR}"/xserverrc.1 xserverrc
		exeinto /etc/X11/xinit/xinitrc.d/
		doexe "${FILESDIR}/00-xhost"
		insinto /usr/share/xsessions
		doins "${FILESDIR}"/Xsession.desktop
	fi
	if use clip-livecd; then
		exeinto "/etc/X11/Sessions"
		newexe "${FILESDIR}/CLIP.livecd" "CLIP"

		exeinto /etc/X11/xinit
		newexe ${FILESDIR}/xinitrc.livecd xinitrc
	fi
}

pkg_postinst() {
	xorg-2_pkg_postinst
	ewarn "If you use startx to start X instead of a login manager like gdm/kdm,"
	ewarn "you can set the XSESSION variable to anything in /etc/X11/Sessions/ or"
	ewarn "any executable. When you run startx, it will run this as the login session."
	ewarn "You can set this in a file in /etc/env.d/ for the entire system,"
	ewarn "or set it per-user in ~/.bash_profile (or similar for other shells)."
	ewarn "Here's an example of setting it for the whole system:"
	ewarn "    echo XSESSION=\"Gnome\" > /etc/env.d/90xsession"
	ewarn "    env-update && source /etc/profile"
}
