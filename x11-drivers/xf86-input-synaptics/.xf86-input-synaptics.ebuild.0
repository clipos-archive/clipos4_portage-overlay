# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit linux-info xorg-2

DESCRIPTION="Driver for Synaptics touchpads"
HOMEPAGE="https://cgit.freedesktop.org/xorg/driver/xf86-input-synaptics/"

KEYWORDS="amd64 arm ~mips ppc ppc64 x86"
IUSE="kernel_linux"
IUSE="${IUSE} clip clip-devstation clip-livecd"

RDEPEND="kernel_linux? ( >=dev-libs/libevdev-0.4 )
	>=x11-base/xorg-server-1.14
	>=x11-libs/libXi-1.2
	>=x11-libs/libXtst-1.1.0"
DEPEND="${RDEPEND}
	>=sys-kernel/linux-headers-2.6.37
	clip-devstation? ( ~sys-kernel/linux-headers-4.4 )
	clip-livecd? ( ~sys-kernel/linux-headers-4.4 )
	>=x11-proto/inputproto-2.1.99.3
	>=x11-proto/recordproto-1.14"

DOCS=( "README" )

PATCHES=(
	"${FILESDIR}"/${PN}-1.3.0-clip-prefix.patch
)
XORG_EAUTORECONF="yes"

pkg_setup() {
	XORG_CONFIGURE_OPTIONS=(
		"--with-xorg-conf-dir=${CPREFIX:-/usr}/share/X11/xorg.conf.d"
		"--with-xorg-sdk-dir=${CPREFIX:-/usr}/include/xorg"
	)
}

pkg_pretend() {
	linux-info_pkg_setup
	# Just a friendly warning
	if ! linux_config_exists \
			|| ! linux_chkconfig_present INPUT_EVDEV; then
		echo
		ewarn "This driver requires event interface support in your kernel"
		ewarn "  Device Drivers --->"
		ewarn "    Input device support --->"
		ewarn "      <*>     Event interface"
		echo
	fi
}

src_install() {
	xorg-2_src_install

	if use clip; then
		exeinto /usr/bin
		doexe "${FILESDIR}/synaptics-settings.sh"
		doexe "${FILESDIR}/xsynaptics-settings.sh"		
	fi
}
