# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

STUPID_NUM="4140"

inherit eutils toolchain-funcs udev autotools-utils

DESCRIPTION="CCID free software driver"
HOMEPAGE="http://pcsclite.alioth.debian.org/ccid.html"
SRC_URI="http://alioth.debian.org/frs/download.php/file/${STUPID_NUM}/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm ~hppa ~ia64 ppc ppc64 ~sparc x86"
IUSE="twinserial +usb clip"

RDEPEND=">=sys-apps/pcsc-lite-1.8.3
	clip? ( usb? ( virtual/libusb1 ) )
	!clip? ( usb? ( virtual/libusb:1 ) )"
DEPEND="${RDEPEND}
	kernel_linux? ( virtual/pkgconfig )"

DOCS=( README AUTHORS )

src_configure() {
	local myeconfargs=(
		LEX=:
		$(use_enable twinserial)
		$(use_enable usb libusb)
	)

	autotools-utils_src_configure
}

src_install() {
	autotools-utils_src_install

	if use kernel_linux && use !clip; then
		# note: for eudev support, rules probably will always need to be
		# installed to /usr

		# ccid >=1.4.11 version changed the rules drastically in a minor
		# release to no longer use the pcscd group. Using the old ones in
		# the mean time.
		##udev_newrules "${FILESDIR}"/92_pcscd_ccid-2.rules 92-pcsc-ccid.rules
		insinto /lib/udev/rules.d
		doins "${FILESDIR}"/92_pcscd_ccid.rules || die
	fi

	if use clip ; then
		rm -rf "${D}"/lib
		rm -f "${D}"/usr/sbin/Kobil_mIDentity_switch
		rm -f "${D}"/usr/bin/RSA_SecurID_getpasswd
	fi
}