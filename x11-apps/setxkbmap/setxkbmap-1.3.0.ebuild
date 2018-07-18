# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/setxkbmap/setxkbmap-1.3.0.ebuild,v 1.9 2012/08/26 16:30:52 armin76 Exp $

EAPI=4

inherit xorg-2 verictl2

DESCRIPTION="Controls the keyboard layout of a running X server."

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 s390 sh sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="clip-core"
RDEPEND="x11-libs/libxkbfile
	x11-libs/libX11"
DEPEND="${RDEPEND}"

pkg_predeb() {
	if use clip-core; then
		VERIEXEC_CTX=504 doverictld2  ${CPREFIX:-/usr}/bin/setxkbmap e - - - c
	fi
}
