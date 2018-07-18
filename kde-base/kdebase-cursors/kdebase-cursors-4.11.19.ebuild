# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KMNAME="kde-workspace"
KMMODULE="cursors"
inherit kde4-meta

DESCRIPTION="oxygen cursors from kdebase"
IUSE=" clip"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~amd64-linux ~x86-linux"

src_prepare() {
kde4-meta_src_prepare
if use clip; then
epatch "${FILESDIR}/${PN}-clip-cprefix.patch"
fi
}
