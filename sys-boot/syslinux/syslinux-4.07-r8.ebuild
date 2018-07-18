# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

inherit eutils toolchain-funcs deb rootdisk

DESCRIPTION="SYSLINUX, PXELINUX, ISOLINUX, EXTLINUX and MEMDISK bootloaders"
HOMEPAGE="http://syslinux.zytor.com/"

EFIVER="6.03"
EFIBIN="syslinux-efi-${EFIVER}"
DISTEFIBIN="${EFIBIN}.tar.bz2"

SRC_URI="mirror://kernel/linux/utils/boot/syslinux/${PV:0:1}.xx/${P/_/-}.tar.bz2
	mirror://clip/${DISTDIR}/${DISTEFIBIN}"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE="custom-cflags clip clip-devstation clip-livecd"

RDEPEND="!clip? (
			sys-fs/mtools
			dev-perl/Crypt-PasswdMD5
			dev-perl/Digest-SHA1
		)
		clip? (
			sys-kernel/clip-kernel
			clip-data/clip-hardware
		)"
DEPEND="${RDEPEND}
	dev-lang/nasm
	virtual/os-headers
	clip-devstation? ( =virtual/os-headers-0-r3 )
	clip-livecd? ( =virtual/os-headers-0-r3 )"

CLIP_CONF_FILES_VIRTUAL="/etc/bootargs"


S=${WORKDIR}/${P/_/-}

# This ebuild is a departure from the old way of rebuilding everything in syslinux
# This departure is necessary since hpa doesn't support the rebuilding of anything other
# than the installers.

# removed all the unpack/patching stuff since we aren't rebuilding the core stuff anymore

src_unpack() {
	unpack ${A}
	cd "${S}"
	# Fix building on hardened
	epatch "${FILESDIR}"/${PN}-4.05-nopie.patch

	rm -f gethostip #bug 137081

	# Don't prestrip or override user LDFLAGS, bug #305783
	local SYSLINUX_MAKEFILES="extlinux/Makefile linux/Makefile mtools/Makefile \
		sample/Makefile utils/Makefile"
	sed -i ${SYSLINUX_MAKEFILES} -e '/^LDFLAGS/d' || die "sed failed"

	if use custom-cflags; then
		sed -i ${SYSLINUX_MAKEFILES} \
			-e 's|-g -Os||g' \
			-e 's|-Os||g' \
			-e 's|CFLAGS[[:space:]]\+=|CFLAGS +=|g' \
			|| die "sed custom-cflags failed"
	else
		QA_FLAGS_IGNORED="
			/sbin/extlinux
			/usr/bin/memdiskfind
			/usr/bin/gethostip
			/usr/bin/isohybrid
			/usr/bin/syslinux
			"
	fi

}

src_compile() {
	emake CC=$(tc-getCC) installer || die
}

src_install() {
	emake INSTALLSUBDIRS=utils INSTALLROOT="${D}" MANDIR=/usr/share/man install || die
	dodoc README NEWS doc/*.txt || die
		if use clip; then
			mkdir -p "${D}/boot/syslinux/bios"
			insinto "/boot/syslinux"
			doins "${FILESDIR}/extlinux_5.conf"
			doins "${FILESDIR}/extlinux_10.conf"
			mv "${D}/usr/share/syslinux/menu.c32" "${D}/boot/syslinux/bios"
			mv "${D}/usr/share/syslinux/linux.c32" "${D}/boot/syslinux/bios"
			mv "${D}/usr/share/syslinux/mbr.bin" "${D}/boot/syslinux/bios"
			rm -fr "${D}/usr"
			for	arch in 32 64; do
				cp -r "${WORKDIR}/${EFIBIN}/efi${arch}" "${D}boot/syslinux/"
			done
		fi
}

pkg_predeb() {
	init_maintainer "postinst"

	gen_rootdisk "postinst" || die ""

	cat "${FILESDIR}/postinst" >> "${D}/DEBIAN/postinst"
}
