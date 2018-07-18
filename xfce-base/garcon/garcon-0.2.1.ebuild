# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/xfce-base/garcon/garcon-0.2.1.ebuild,v 1.3 2013/12/31 08:49:14 maekke Exp $

EAPI=5
inherit xfconf

DESCRIPTION="Xfce's freedesktop.org specification compatible menu implementation library"
HOMEPAGE="http://www.xfce.org/projects/libraries/"
SRC_URI="mirror://xfce/src/libs/${PN}/${PV%.*}/${P}.tar.bz2"

LICENSE="LGPL-2 FDL-1.1"
SLOT="0"
KEYWORDS="~alpha ~amd64 arm hppa ~ia64 ~mips ~ppc ~ppc64 ~sh ~sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~x86-linux ~x86-solaris"
IUSE="debug clip-deps"

RDEPEND="!clip-deps? ( >=dev-libs/glib-2.14 )
	>=xfce-base/libxfce4util-4.10.1"
DEPEND="${RDEPEND}
	dev-util/intltool
	sys-devel/gettext
	virtual/pkgconfig"

pkg_setup() {
	XFCONF=(
		$(xfconf_use_debug)
		--with-html-dir="${CPREFIX:-"${EPREFIX}"/usr}"/share/doc/${PF}/html
		)

	DOCS=( AUTHORS ChangeLog HACKING NEWS README STATUS TODO )
}