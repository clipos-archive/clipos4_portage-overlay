# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5  # CLIP: backported from EAPI 6
inherit autotools eutils flag-o-matic multilib pam

DESCRIPTION="A modular screen saver and locker for the X Window System"
HOMEPAGE="https://www.jwz.org/xscreensaver/"
SRC_URI="
	${HOMEPAGE}${P}.tar.gz
"

LICENSE="BSD"
SLOT="0"
KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~sh sparc x86 ~x86-fbsd ~amd64-linux ~x86-linux ~x64-solaris ~x86-solaris"
IUSE="gdm jpeg new-login offensive opengl pam +perl selinux suid xinerama"
IUSE="${IUSE} clip core-deps clip-devstation"

COMMON_DEPEND="
	!clip-devstation? ( !clip? (
		>=gnome-base/libglade-2
		dev-libs/libxml2
		media-libs/netpbm
		x11-apps/appres
		x11-apps/xwininfo
		x11-libs/gdk-pixbuf:2[X]
		x11-libs/gtk+:2
	) )
	x11-libs/libX11
	x11-libs/libXext
	x11-libs/libXi
	x11-libs/libXmu
	x11-libs/libXrandr
	x11-libs/libXt
	x11-libs/libXxf86misc
	x11-libs/libXxf86vm
	!core-deps? ( jpeg? ( virtual/jpeg:0 ) )
	new-login? (
		gdm? ( gnome-base/gdm )
		!gdm? ( || ( x11-misc/lightdm lxde-base/lxdm ) )
		)
	opengl? (
		virtual/glu
		virtual/opengl
	)
	pam? ( virtual/pam )
	xinerama? ( x11-libs/libXinerama )
"
# For USE="perl" see output of `qlist xscreensaver | grep bin | xargs grep '::'`
RDEPEND="
	${COMMON_DEPEND}
	!clip? (
		perl? (
			dev-lang/perl
			dev-perl/libwww-perl
			virtual/perl-Digest-MD5
		)
	)
	selinux? ( sec-policy/selinux-xscreensaver )
"
DEPEND="
	${COMMON_DEPEND}
	dev-util/intltool
	sys-devel/bc
	sys-devel/gettext
	virtual/pkgconfig
	x11-proto/recordproto
	x11-proto/scrnsaverproto
	x11-proto/xextproto
	x11-proto/xf86miscproto
	x11-proto/xf86vidmodeproto
	xinerama? ( x11-proto/xineramaproto )
"

MAKEOPTS="${MAKEOPTS} -j1"

CLIP_CONF_FILES="/etc/admin/conf.d/xscreensaver"

src_prepare() {
	sed -i configure.in -e '/^ALL_LINGUAS=/d' || die
	strip-linguas -i po/
	export ALL_LINGUAS="${LINGUAS}"

	if use new-login && ! use gdm; then #392967
		sed -i \
			-e "/default_l.*1/s:gdmflexiserver -ls:${EPREFIX}/usr/libexec/lightdm/&:" \
			configure{,.in} || die
	fi

	# CLIP: EAPI 6 backport: eapply=>epatch
	epatch \
		"${FILESDIR}"/${PN}-5.05-interix.patch \
		"${FILESDIR}"/${PN}-5.20-blurb-hndl-test-passwd.patch \
		"${FILESDIR}"/${PN}-5.20-test-passwd-segv-tty.patch \
		"${FILESDIR}"/${PN}-5.20-tests-miscfix.patch \
		"${FILESDIR}"/${PN}-5.28-comment-style.patch \
		"${FILESDIR}"/${PN}-5.31-pragma.patch \
		"${FILESDIR}"/${PN}-5.35-gentoo.patch

	# CLIP: EAPI 6 backport: eapply=>epatch
	use offensive || epatch "${FILESDIR}"/${PN}-5.35-offensive.patch

	if use clip || use clip-devstation ; then
		sed -i -e 's:utils driver hacks hacks/glx po:utils driver po:' \
			"${S}"/Makefile.in || die "sed failed"
		sed -i -e 's:xscreensaver-demo[ \t\n]::g; s:xscreensaver-getimage[ \t\n]::g' \
			"${S}"/driver/Makefile.in || die "sed failed"
		epatch "${FILESDIR}"/${PN}-5.10-clip-fr.patch
		epatch "${FILESDIR}"/${PN}-5.10-clip-exthelper.patch
		epatch "${FILESDIR}"/${PN}-5.03-clip-allow-adm-lock.patch
		epatch "${FILESDIR}"/${PN}-5.36-clip-esc-menu.patch
		epatch "${FILESDIR}"/${PN}-5.36-clip-event-lock.patch
		epatch "${FILESDIR}"/${PN}-5.15-clip-no-detect-overlap.patch
		[[ "${CPREFIX}" == "/usr/local" ]] && epatch "${FILESDIR}/${PN}-5.10-clip-prefix.patch"
		epatch "${FILESDIR}"/${PN}-5.36-clip-no-hacks.patch

		# Yead, I know this is bad...
		for s in 50 180; do 
			cp "${FILESDIR}/logo-${s}.xpm" "${S}/utils/images"
		done
	fi

	# CLIP: EAPI 6 backport: eapply=>epatch
	epatch_user

	eautoconf
	eautoheader
}

src_configure() {
	if use ppc || use ppc64; then
		filter-flags -maltivec -mabi=altivec
		append-flags -U__VEC__
	fi

	unset BC_ENV_ARGS #24568
	export RPM_PACKAGE_VERSION=no #368025
	local txtfile="/etc/gentoo-release"
	use clip && txtfile="/etc/shared/clip-release"
	local conf="--with-proc-interrupts"
	use clip && conf="--without-proc-interrupts --without-shadow --with-passwd-helper=/usr/local/bin/xscreensaver-pwcheck --disable-root-passwd"
	use clip && export LIBS="-lXtst"

	econf \
		$(use_with jpeg) \
		$(use_with new-login login-manager) \
		$(use_with opengl gl) \
		$(use_with pam) \
		$(use_with suid setuid-hacks) \
		$(use_with xinerama xinerama-ext) \
		--enable-locking \
		--with-configdir="${EPREFIX}${CPREFIX:-/usr}"/share/${PN}/config \
		--with-dpms-ext \
		--with-gtk \
		--with-hackdir="${EPREFIX}${CPREFIX:-/usr}"/$(get_libdir)/misc/${PN} \
		--with-pixbuf \
		--with-proc-interrupts \
		--with-randr-ext \
		--with-text-file="${EPREFIX}"/etc/gentoo-release \
		--with-x-app-defaults="${EPREFIX}${CPREFIX:-/usr}"/share/X11/app-defaults \
		--with-xdbe-ext \
		--with-xf86gamma-ext \
		--with-xf86vmode-ext \
		--with-xinput-ext \
		--with-xshm-ext \
		--without-gle \
		--without-kerberos \
		--x-includes="${EPREFIX}"/usr/include \
		--x-libraries="${EPREFIX}${CPREFIX:-/usr}"/$(get_libdir) \
		--with-text-file="${EPREFIX}${txtfile}" \
		${conf}
}

src_install() {
	emake install_prefix="${D}" install

	dodoc README{,.hacking}

	use pam && fperms 755 /usr/bin/${PN}
	use clip && fperms 755 /usr/bin/xscreensaver
	pamd_mimic_system ${PN} auth

	rm -f "${ED}${CPREFIX:-/usr}"/share/${PN}/config/{electricsheep,fireflies}.xml
	if use clip; then
		# glade garbage
		rm -fr "${D}/xscreensaver"
		insinto /usr/share/X11/app-defaults
		doins "${FILESDIR}"/XScreenSaver
		exeinto /usr/bin
		doexe "${FILESDIR}"/xscreensaver-settime.sh
		doexe "${FILESDIR}"/xscreensaver-lock.sh
		doexe "${FILESDIR}"/xreset.sh
	fi
}
