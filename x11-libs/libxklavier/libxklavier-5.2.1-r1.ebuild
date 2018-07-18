# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libxklavier/libxklavier-5.2.ebuild,v 1.2 2012/01/23 18:58:22 ssuominen Exp $

EAPI=4
inherit gnome.org libtool

DESCRIPTION="A library for the X Keyboard Extension (high-level API)"
HOMEPAGE="http://www.freedesktop.org/wiki/Software/LibXklavier"

LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~ppc ~ppc64 ~sh ~sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="doc introspection clip-deps"

RDEPEND="app-text/iso-codes
	!clip-deps? ( >=dev-libs/glib-2.16 )
	dev-libs/libxml2
	x11-apps/xkbcomp
	x11-libs/libX11
	>=x11-libs/libXi-1.1.3
	x11-libs/libxkbfile
	>=x11-misc/xkeyboard-config-2.4.1-r3
	introspection? ( >=dev-libs/gobject-introspection-1.30 )"
DEPEND="${RDEPEND}
	virtual/pkgconfig
	sys-devel/gettext
	doc? ( >=dev-util/gtk-doc-1.4 )"

DOCS="AUTHORS ChangeLog CREDITS NEWS README"

src_prepare() {
	elibtoolize
}

src_configure() {
	econf \
		--disable-static \
		$(use_enable introspection) \
		$(use_enable doc gtk-doc) \
		--with-html-dir="${EPREFIX}${CPREFIX:-/usr}"/share/doc/${PF}/html \
		--with-xkb-base="${EPREFIX}${CPREFIX:-/usr}"/share/X11/xkb \
		--with-xkb-bin-base="${EPREFIX}${CPREFIX:-/usr}"/bin

	if [[ -n "${CPREFIX}" ]]; then
		sed -i \
			-e "s:ISO_CODES_PREFIX \"/usr\":ISO_CODES_PREFIX \"${CPREFIX}\":" \
			-e "s:XMODMAP_BASE \"/usr/share:XMODMAP_BASE \"${CPREFIX}/share:" \
			"${S}/config.h" || die
	fi
}

src_install() {
	default
	find "${ED}" -name '*.la' -exec rm -f {} +
}
