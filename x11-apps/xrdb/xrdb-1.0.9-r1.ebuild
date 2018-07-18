# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xrdb/xrdb-1.0.9.ebuild,v 1.1 2011/04/05 17:11:22 scarabeus Exp $

EAPI=3

inherit xorg-2

DESCRIPTION="X server resource database utility"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc x86 ~x86-fbsd ~x86-interix ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x64-solaris ~x86-solaris"
IUSE="clip"

RDEPEND="x11-libs/libXmu
	x11-libs/libX11
	clip? ( dev-cpp/libmcpp )"
DEPEND="${RDEPEND}"

pkg_setup() {
	use clip && XORG_CONFIGURE_OPTIONS=( "--with-cpp=${CPREFIX:-/usr}/bin/cpp" )
}
src_prepare() {
	xorg-2_src_prepare
}
