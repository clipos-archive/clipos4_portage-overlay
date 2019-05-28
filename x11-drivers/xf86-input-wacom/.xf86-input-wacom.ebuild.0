# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit linux-info xorg-2

DESCRIPTION="Driver for Wacom tablets and drawing devices"
HOMEPAGE="http://linuxwacom.sourceforge.net/"
LICENSE="GPL-2"
EGIT_REPO_URI="git://git.code.sf.net/p/linuxwacom/${PN}"
[[ ${PV} != 9999* ]] && \
	SRC_URI="mirror://sourceforge/linuxwacom/${PN}/${P}.tar.bz2"

KEYWORDS="alpha amd64 arm ia64 ppc ppc64 sparc x86"
IUSE="debug"
IUSE="${IUSE} clip"

# depend on libwacom for its udev rules, bug #389633
RDEPEND="dev-libs/libwacom
	!clip? (
		virtual/udev
	)
	>=x11-base/xorg-server-1.7
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libXinerama"
DEPEND="${RDEPEND}
	x11-proto/randrproto"

PATCHES=(
	"${FILESDIR}/${P}-xorg-server-1.19-support.patch"
)

pkg_setup() {
	if use clip; then
		PATCHES+=(
				"${FILESDIR}/${PN}-0.23.0-clip-hotplug.patch" 
				"${FILESDIR}/${PN}-0.34.0-clip-no-udev.patch" 
		)
		XORG_EAUTORECONF="yes"
	fi
	linux-info_pkg_setup

	XORG_CONFIGURE_OPTIONS=(
		$(use_enable debug)
		"--with-xorg-conf-dir=${CPREFIX:-/usr}/share/X11/xorg.conf.d"
	)
}

src_install() {
	xorg-2_src_install

	rm -rf "${ED}${CPREFIX:-/usr}"/share/hal
	if use clip; then 
		rm -fr "${ED}/usr/include"
		insinto /usr/share/X11/xorg.conf.d
		doins "${FILESDIR}"/50-wacom.conf
	fi
}

pkg_pretend() {
	linux-info_pkg_setup

	if kernel_is lt 3 17; then
		if ! linux_config_exists \
				|| ! linux_chkconfig_present TABLET_USB_WACOM \
				|| ! linux_chkconfig_present INPUT_EVDEV; then
			echo
			ewarn "If you use a USB Wacom tablet, you need to enable support in your kernel"
			ewarn "  Device Drivers --->"
			ewarn "    Input device support --->"
			ewarn "      <*>   Event interface"
			ewarn "      [*]   Tablets  --->"
			ewarn "        <*>   Wacom Intuos/Graphire tablet support (USB)"
			echo
		fi
	else
		if ! linux_config_exists \
				|| ! linux_chkconfig_present HID_WACOM; then
			echo
			ewarn "If you use a USB Wacom tablet, you need to enable support in your kernel"
			ewarn "  Device Drivers --->"
			ewarn "    HID support  --->"
			ewarn "      Special HID drivers  --->"
			ewarn "        <*> Wacom Intuos/Graphire tablet support (USB)"
			echo
		fi
	fi

}
