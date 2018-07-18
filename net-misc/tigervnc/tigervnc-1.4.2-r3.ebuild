# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

inherit eutils cmake-utils autotools java-pkg-opt-2 flag-o-matic

PATCHVER="0.1"
XSERVER_VERSION="1.17.1"
# CLIP
XSERVER_VERSION="1.17.4"
OPENGL_DIR="xorg-x11"
#MY_P="${PN}-1.2.80-20130314svn5065"
#S="${WORKDIR}/${MY_P}"

DESCRIPTION="Remote desktop viewer display system"
HOMEPAGE="http://www.tigervnc.org"
SRC_URI="https://github.com/TigerVNC/tigervnc/archive/v${PV}.tar.gz -> ${P}.tar.gz
	mirror://gentoo/${PN}.png
	mirror://gentoo/${P}-patches-${PATCHVER}.tar.bz2
	https://dev.gentoo.org/~armin76/dist/${P}-patches-${PATCHVER}.tar.bz2
	server? ( ftp://ftp.freedesktop.org/pub/xorg/individual/xserver/xorg-server-${XSERVER_VERSION}.tar.bz2 )"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ~ia64 ~mips ~ppc ppc64 ~sh ~sparc x86"
IUSE="gnutls java nptl +opengl pam server +xorgmodule"
IUSE="${IUSE} clip clip-deps core-deps clip-rm serveronly clip-devstation"

RDEPEND="
	!clip-deps? (
		sys-libs/zlib
	)
	!core-deps? (
		virtual/jpeg:0
		pam? ( virtual/pam )
	)
	>=x11-libs/libXtst-1.0.99.2
	!serveronly? (
		>=x11-libs/fltk-1.3.1
	)
	gnutls? ( net-libs/gnutls )
	java? ( >=virtual/jre-1.5 )
	server? (
		clip? ( >=dev-libs/nettle-3.1.1 )
		clip-devstation? ( >=dev-libs/nettle-3.1.1 )
		!clip? ( dev-lang/perl )
		>=x11-libs/libXi-1.2.99.1
		>=x11-libs/libXfont-1.4.2
		>=x11-libs/libxkbfile-1.0.4
		x11-libs/libXrender
		>=x11-libs/pixman-0.27.2
		>=x11-apps/xauth-1.0.3
		x11-apps/xsetroot
		>=x11-misc/xkeyboard-config-2.4.1-r3
		clip? (
			x11-apps/setxkbmap
		)
		!clip? (
			opengl? ( >=app-eselect/eselect-opengl-1.0.8 )
		)
		xorgmodule? ( =x11-base/xorg-server-${XSERVER_VERSION%.*}* )
	)
	!net-misc/vnc
	!net-misc/tightvnc
	!net-misc/xf4vnc"
DEPEND="${RDEPEND}
	amd64? ( dev-lang/nasm )
	x86? ( dev-lang/nasm )
	>=x11-proto/inputproto-2.2.99.1
	>=x11-proto/xextproto-7.2.99.901
	>=x11-proto/xproto-7.0.26
	java? ( >=virtual/jdk-1.5 )
	serveronly? (
		>=x11-libs/fltk-1.3.1
	)
	server? (
		virtual/pkgconfig
		media-fonts/font-util
		x11-misc/util-macros
		>=x11-proto/bigreqsproto-1.1.0
		>=x11-proto/compositeproto-0.4
		>=x11-proto/damageproto-1.1
		>=x11-proto/fixesproto-5.0
		>=x11-proto/fontsproto-2.1.3
		>=x11-proto/glproto-1.4.17
		>=x11-proto/randrproto-1.4.0
		>=x11-proto/renderproto-0.11
		>=x11-proto/resourceproto-1.2.0
		>=x11-proto/scrnsaverproto-1.1
		>=x11-proto/videoproto-2.2.2
		>=x11-proto/xcmiscproto-1.2.0
		>=x11-proto/xineramaproto-1.1.3
		>=x11-libs/xtrans-1.3.3
		>=x11-proto/dri2proto-2.8
		opengl? ( >=media-libs/mesa-7.8_rc[nptl=] )
	)"

CMAKE_IN_SOURCE_BUILD=1

pkg_setup() {
	if ! use server ; then
		echo
		einfo "The 'server' USE flag will build tigervnc's server."
		einfo "If '-server' is chosen only the client is built to save space."
		einfo "Stop the build now if you need to add 'server' to USE flags.\n"
	else
		ewarn "Forcing on xorg-x11 for new enough glxtokens.h..."
		OLD_IMPLEM="$(eselect opengl show)"
		eselect opengl set ${OPENGL_DIR}
	fi
}

switch_opengl_implem() {
	# Switch to the xorg implementation.
	# Use new opengl-update that will not reset user selected
	# OpenGL interface ...
	echo
	eselect opengl set ${OLD_IMPLEM}
}

src_prepare() {
	if use server ; then
		cp -r "${WORKDIR}"/xorg-server-${XSERVER_VERSION}/* unix/xserver
	else
		rm "${WORKDIR}"/patches/*_server_*
	fi

	EPATCH_SOURCE="${WORKDIR}/patches" EPATCH_SUFFIX="patch" EPATCH_EXCLUDE="*100*" \
		EPATCH_FORCE="yes" epatch

	if use server ; then
		cd unix/xserver
		epatch "${WORKDIR}"/patches/1000_server_xserver-1.16-rebased.patch
		epatch "${WORKDIR}"/patches/1005_server_xserver-1.17.patch
		epatch "${FILESDIR}"/tigervnc-1.4.2-byteorder.patch
		if use clip; then
			epatch "${FILESDIR}/xorg-server-1.17.4-clip-cprefix.patch"
		fi
		eautoreconf
	fi

	cd "${S}"
	if use clip; then
		epatch "${FILESDIR}/fix-fl-move-button-press.patch"
		epatch "${FILESDIR}/${PN}-1.4.2-clip-unix.patch"
		epatch "${FILESDIR}/${PN}-1.4.2-clip-window-title.patch"
		epatch "${FILESDIR}/${PN}-1.4.2-clip-disable-viewer-hotkeys.patch"
		epatch "${FILESDIR}/${PN}-1.4.2-clip-disable-vncserver-hotkeys.patch"
	fi
	if use clip-rm; then
		epatch "${FILESDIR}/${PN}-1.4.2-clip-rm-modes.patch"
	fi
}

src_configure() {

	use arm || use hppa && append-flags "-fPIC"

	mycmakeargs=(
		-G "Unix Makefiles"
		$(cmake-utils_use_enable gnutls GNUTLS)
		$(cmake-utils_use_enable pam PAM)
		$(cmake-utils_use_build java JAVA)
	)

	cmake-utils_src_configure

	if use server; then
		local xkbout="/var/lib/xkb"
		local myconf=""
		if use clip; then
			xkbout="/tmp"
			myconf="--with-default-xkb-layout=fr --with-default-xkb-variant=oss"
			use server && myconf="${myconf} --with-dri-driver-dir=${CPREFIX:-/usr}/lib/dri"
		fi
		cd unix/xserver
		econf \
			$(use_enable nptl glx-tls) \
			$(use_enable opengl glx) \
			--disable-config-hal \
			--disable-config-udev \
			--disable-devel-docs \
			--disable-dmx \
			--disable-dri \
			--disable-dri3 \
			--disable-kdrive \
			--disable-selective-werror \
			--disable-silent-rules \
			--disable-static \
			--disable-unit-tests \
			--disable-xephyr \
			--disable-xinerama \
			--disable-xnest \
			--disable-xorg \
			--disable-xvfb \
			--disable-xwin \
			--disable-xwayland \
			--enable-dri2 \
			--with-xkb-output=${xkbout} \
			--disable-xcsecurity \
			$(use_enable !clip dpms) \
			${myconf} \
			--with-pic \
			--without-dtrace \
			--disable-present \
			--disable-unit-tests
	fi
}

src_compile() {
	cmake-utils_src_compile

	if use server ; then
		cd unix/xserver
		emake
	fi
}

src_install() {
	local base="${CPREFIX:-/usr}"
	cmake-utils_src_install

	newicon "${DISTDIR}"/tigervnc.png vncviewer.png
	make_desktop_entry vncviewer vncviewer vncviewer Network

	if use server ; then
		cd unix/xserver/hw/vnc
		emake DESTDIR="${D}" install
		! use xorgmodule && rm -rf "${D}${base}"/$(get_libdir)/xorg

		if ! use clip; then
			newconfd "${FILESDIR}"/${PN}.confd ${PN}
			newinitd "${FILESDIR}"/${PN}.initd ${PN}
		fi

		if use serveronly; then
			for f in vncserver x0vncserver vncconfig vncviewer; do
				rm "${D}${base}"/bin/$f
			done
			rm -fr "${D}/${base}/share"
		fi
		rm "${D}${base}"/$(get_libdir)/xorg/modules/extensions/libvnc.la
	else
		cd "${D}"
		for f in vncserver vncpasswd x0vncserver vncconfig; do
			rm ${cPREFIX:-usr}/bin/$f
			rm ${cPREFIX:-usr}/share/man/man1/$f.1
		done
		if use clip; then
			mkdir bin
			mv ${cPREFIX:-usr}/bin/* bin/
			rm -fr ${cPREFIX:-usr} usr
		fi
	fi
	if use clip ;then
		if use server; then
			exeinto /usr/bin
			doexe "${FILESDIR}/XClip"
			doexe "${FILESDIR}/set-screen-size.sh"
		else
			export CPREFIX=""
			exeinto /bin
			doexe "${FILESDIR}/viewer.sh"
		fi
	fi
}

pkg_postinst() {
	use server && switch_opengl_implem
}
