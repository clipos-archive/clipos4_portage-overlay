# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit linux-info xorg-2

DESCRIPTION="Generic Linux input driver"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~sh sparc x86"
IUSE=""
IUSE="${IUSE} clip clip-devstation clip-livecd"

RDEPEND="!clip-devstation? ( !clip? ( >=x11-base/xorg-server-1.18[udev] ) )
	clip-devstation? ( clip? ( >=x11-base/xorg-server-1.18 ) )
	dev-libs/libevdev
	sys-libs/mtdev
	!clip? ( virtual/libudev:= )"
DEPEND="${RDEPEND}
	>=x11-proto/inputproto-2.1.99.3
	>=sys-kernel/linux-headers-2.6
	clip-devstation? ( ~sys-kernel/linux-headers-4.4 )
	clip-livecd? ( ~sys-kernel/linux-headers-4.4 )
"

pkg_pretend() {
	if use kernel_linux ; then
		CONFIG_CHECK="~INPUT_EVDEV"
	fi
	check_extra_config
}

pkg_setup() {
	if use clip; then
		PATCHES+=( "${FILESDIR}/${PN}-2.10.5-clip-no-udev.patch" )
		XORG_EAUTORECONF="yes"
	fi
}

src_install() {
	xorg-2_src_install

	if use clip; then 
		rm -fr "${ED}/usr/include"
		insinto /usr/share/X11/xorg.conf.d
		doins "${FILESDIR}"/51-panjit.conf
		doins "${FILESDIR}"/51-ntrig.conf
	fi
}

