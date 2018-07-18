# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

XORG_DOC=doc
XORG_MULTILIB=yes
inherit xorg-2

DESCRIPTION="X.Org Xext library"

KEYWORDS="alpha amd64 arm ~arm64 hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE=""
IUSE="${IUSE} clip-domains"

# CLIP: x11-proto/xextproto moved from RDEPEND to DEPEND since useless in
# target.
RDEPEND=">=x11-libs/libX11-1.6.2:=[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	>=x11-proto/xextproto-7.2.1-r1:=[${MULTILIB_USEDEP}]"

src_configure() {
	XORG_CONFIGURE_OPTIONS=(
		$(use_enable doc specs)
		$(use_with doc xmlto)
		--without-fop
	)
	xorg-2_src_configure
}