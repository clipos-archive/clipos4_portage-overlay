# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/librsvg/librsvg-2.39.0.ebuild,v 1.5 2013/12/22 16:04:55 jer Exp $

EAPI="5"
GCONF_DEBUG="no"
GNOME2_LA_PUNT="yes"
VALA_MIN_API_VERSION="0.18"
VALA_USE_DEPEND="vapigen"

inherit autotools eutils gnome2 multilib vala gnome2-postinst

DESCRIPTION="Scalable Vector Graphics (SVG) rendering library"
HOMEPAGE="https://live.gnome.org/LibRsvg"

LICENSE="LGPL-2"
SLOT="2"
KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~x64-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="+gtk +introspection tools vala"
IUSE="${IUSE} clip clip-deps"
REQUIRED_USE="
	vala? ( introspection )
	tools? ( gtk )
"

RDEPEND="
	!clip-deps? (
		>=dev-libs/glib-2.24:2
	)
	>=x11-libs/cairo-1.2
	>=x11-libs/pango-1.32.6
	>=dev-libs/libxml2-2.7:2
	>=dev-libs/libcroco-0.6.1
	x11-libs/gdk-pixbuf:2[introspection?]
	gtk? (
		>=x11-libs/gtk+-2.16:2
		tools? ( >=x11-libs/gtk+-3:3 ) )
	introspection? ( >=dev-libs/gobject-introspection-0.10.8 )
"
DEPEND="${RDEPEND}
	dev-libs/gobject-introspection-common
	dev-libs/vala-common
	>=dev-util/gtk-doc-am-1.13
	virtual/pkgconfig
	vala? ( $(vala_depend) )
"
# >=gtk-doc-am-1.13, gobject-introspection-common, vala-common needed by eautoreconf

src_prepare() {
	# Make rsvg-view non-automagic, upstream bug #653323
	epatch "${FILESDIR}/${PN}-2.36.0-rsvg-view-automagic.patch"
	# Fix compilation on non-GNU libcs, from upstream
	epatch "${FILESDIR}"/${P}-canonicalize-realpath.patch

	use clip && epatch "${FILESDIR}/${PN}-2.34.2-gdk-pixbuf-cprefix.patch"

	use vala && vala_src_prepare

	eautoreconf
	gnome2_src_prepare
}

src_configure() {
	local myconf=""

	# -Bsymbolic is not supported by the Darwin toolchain
	if [[ ${CHOST} == *-darwin* ]]; then
		myconf="${myconf} --disable-Bsymbolic"
	fi

	use clip && myconf="${myconf}
		--with-pixbuf-dir=${CPREFIX:-/usr}/$(get_libdir)/gdk-pixbuf-2.0/2.10.0"
	gnome2_src_configure \
		--disable-static \
		--disable-tools \
		$(use_enable tools rsvg-view) \
		$(use_enable gtk gtk-theme) \
		$(use_enable introspection) \
		$(use_enable vala) \
		--enable-pixbuf-loader \
		${myconf}
}

src_compile() {
	# causes segfault if set, see bug #411765
	unset __GL_NO_DSO_FINALIZER
	gnome2_src_compile
}

pkg_postinst() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER
	gnome2_pkg_postinst
}

pkg_postrm() {
	# causes segfault if set, see bug 375615
	unset __GL_NO_DSO_FINALIZER
	gnome2_pkg_postrm
}
