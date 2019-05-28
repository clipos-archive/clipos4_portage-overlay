# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/media-sound/alsa-utils/alsa-utils-1.0.27.2.ebuild,v 1.1 2013/07/18 16:49:34 ssuominen Exp $

EAPI=5
inherit eutils systemd udev

DESCRIPTION="Advanced Linux Sound Architecture Utils (alsactl, alsamixer, etc.)"
HOMEPAGE="http://www.alsa-project.org/"
SRC_URI="mirror://alsaproject/utils/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0.9"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc x86"
IUSE="doc +libsamplerate +ncurses nls selinux clip clip-core rm-deps"

RDEPEND=">=media-libs/alsa-lib-1.0.27.1
	clip-core? ( 
		>=app-clip/hotplug-clip-2.5.11
		>=clip-libs/clip-sub-1.6.0
	)
	libsamplerate? ( media-libs/libsamplerate )
	!rm-deps? ( ncurses? ( >=sys-libs/ncurses-5.7-r7 ) )
	selinux? ( sec-policy/selinux-alsa )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	doc? ( app-text/xmlto )"

src_prepare() {
	epatch "${FILESDIR}/${PN}-clip-louder-volume-by-default.patch"
	epatch_user
}

src_configure() {
	local myconf
	use doc || myconf='--disable-xmlto'

	# --disable-alsaconf because it doesn't work with sys-apps/kmod wrt #456214
	econf \
		--disable-maintainer-mode \
		$(use_enable libsamplerate alsaloop) \
		$(use_enable nls) \
		$(use_enable ncurses alsamixer) \
		--disable-alsaconf \
		"$(systemd_with_unitdir)" \
		--with-udev-rules-dir="$(get_udevdir)"/rules.d \
		${myconf}
}

src_install() {
	emake DESTDIR="${D}" install
	dodoc ChangeLog README TODO seq/*/README.*

	if use clip; then
		rm -fr "${ED}$(get_udevdir)"
		rmdir "${ED}/lib" 2>/dev/null

		# root:audio
		fowners 0:18 "/usr/bin/alsamixer"
		fperms 2755 "/usr/bin/alsamixer"
	else
		newinitd "${FILESDIR}"/alsasound.initd-r5 alsasound
		newconfd "${FILESDIR}"/alsasound.confd-r4 alsasound

		insinto /etc/modprobe.d
		newins "${FILESDIR}"/alsa-modules.conf-rc alsa.conf
	fi

	if use clip-core; then
		exeinto /lib/devices.d
		newexe "${FILESDIR}/sound.devices.d" "sound"
	fi

	keepdir /var/lib/alsa

	# ALSA lib parser.c:1266:(uc_mgr_scan_master_configs) error: could not
	# scan directory /usr/share/alsa/ucm: No such file or directory
	# alsaucm: unable to obtain card list: No such file or directory
	keepdir /usr/share/alsa/ucm
}

pkg_postinst() {
	if [[ -z ${REPLACING_VERSIONS} ]]; then
		elog
		elog "To take advantage of the init script, and automate the process of"
		elog "saving and restoring sound-card mixer levels you should"
		elog "add alsasound to the boot runlevel. You can do this as"
		elog "root like so:"
		elog "# rc-update add alsasound boot"
		ewarn
		ewarn "The ALSA core should be built into the kernel or loaded through other"
		ewarn "means. There is no longer any modular auto(un)loading in alsa-utils."
	fi
}
