# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-apps/pcsc-lite/pcsc-lite-1.6.6.ebuild,v 1.8 2011/01/10 11:09:39 xarthisius Exp $

EAPI="3"

inherit eutils autotools deb pax-utils verictl2

DESCRIPTION="PC/SC Architecture smartcard middleware library"
HOMEPAGE="http://pcsclite.alioth.debian.org/"

STUPID_NUM="3479"
MY_P="${PN}-${PV/_/-}"
SRC_URI="http://alioth.debian.org/download.php/${STUPID_NUM}/${MY_P}.tar.bz2"
S="${WORKDIR}/${MY_P}"

LICENSE="as-is"
SLOT="0"
KEYWORDS="amd64 arm hppa ia64 m68k ppc ppc64 s390 sh sparc x86"
IUSE="usb kernel_linux core-deps clip clip-core twinserial"

RDEPEND="!clip? ( usb? ( virtual/libusb:1 ) ) 
	clip? ( usb? ( virtual/libusb1 ) )
	clip-core? ( clip-libs/clip-libvserver )"
DEPEND="${RDEPEND}
	dev-util/pkgconfig"
RDEPEND="${RDEPEND}
	!<app-crypt/ccid-1.4.7
	kernel_linux? ( !clip? ( sys-fs/udev ) )"


src_unpack() {
	unpack ${A}
	cd "${S}"
	if use clip-core ; then
		epatch "${FILESDIR}"/${P}-clip.patch
	fi
}

src_configure() {
	ADDLIBS=""
	if use clip ; then
		ADDLIBS="${ADDLIBS} -lclip"
	fi
	if use clip-core ; then
		ADDLIBS="${ADDLIBS} -lclipvserver"
	fi
	LIBS="$ADDLIBS" econf \
		--disable-maintainer-mode \
		--disable-dependency-tracking \
		--enable-usbdropdir="/usr/$(get_libdir)/readers/usb" \
		$(use_enable usb libusb) \
		$(use_enable usb) \
		$(use_enable twinserial serial) \
		--disable-libudev
}

src_install() {
	dodoc AUTHORS DRIVERS HELP README SECURITY ChangeLog || die


	emake DESTDIR="${D}" install || die "emake failed"

	if use clip-core; then
		local ctx=$(cat "${FILESDIR}/jails/pcsc/context")
		insinto "/etc/jails/pcsc"
		doins "${FILESDIR}"/jails/pcsc/*
		if [[ "${ARCH}" =~ ^.*64$ ]] ; then
			dodir "/var/lib/pcsc/usr/lib64/"
			dosym lib64 /var/lib/pcsc/usr/lib
			sed -i -e '/@clip32@/d' ${D}/etc/jails/pcsc/fstab.external
			sed -i -e 's/@clip64@//' ${D}/etc/jails/pcsc/fstab.external
		else
			dodir "/var/lib/pcsc/usr/lib/"
			sed -i -e 's/@clip32@//' ${D}/etc/jails/pcsc/fstab.external
			sed -i -e '/@clip64@/d' ${D}/etc/jails/pcsc/fstab.external
		fi
		dodir "/var/lib/pcsc/dev/bus/usb"
		dodir "/var/lib/pcsc/var/run/pcscd"
		dodir "/var/lib/pcsc/var/run/smartcard"
		dodir "/var/lib/pcsc/usr/lib"
		dodir "/var/lib/pcsc/sys"
	fi

	dodir "/var/run/pcscd"
	dodir "/var/run/smartcard"

	if use kernel_linux && use !clip ; then
		insinto /lib/udev/rules.d
		doins "${FILESDIR}"/99-pcscd-hotplug.rules || die
	fi

	if use clip ; then
		newinitd "${FILESDIR}/pcscd-init.4.clip" pcscd || die
		rm -rf ${D}/usr/lib/libpcscspy.*
		rm -rf ${D}/usr/lib/pkgconfig
		rm -rf ${D}/usr/bin
	else
		newinitd "${FILESDIR}/pcscd-init.4" pcscd || die
	fi
}

pkg_predeb() {
	if use clip-core; then
		doverictld2 /usr/sbin/pcscd er 'CONTEXT|SYS_ADMIN' 'CONTEXT|SYS_ADMIN' - -
	fi
}
