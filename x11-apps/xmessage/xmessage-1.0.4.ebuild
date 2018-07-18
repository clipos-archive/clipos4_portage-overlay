# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-apps/xmessage/xmessage-1.0.4.ebuild,v 1.11 2013/10/08 05:04:17 ago Exp $

EAPI=5

inherit xorg-2

DESCRIPTION="display a message or query in a window (X-based /bin/echo)"

KEYWORDS="alpha amd64 arm hppa ia64 ~mips ppc ppc64 ~s390 ~sh sparc x86 ~amd64-fbsd ~x86-fbsd ~x86-interix ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="clip"

RDEPEND="x11-libs/libXaw
	x11-libs/libXt"
DEPEND="${RDEPEND}"

src_configure() {
	xorg-2_src_configure
	[[ -n "${CPREFIX}" ]] && \
		sed -i -e "s:appdefaultdir = /usr:appdefaultdir = ${CPREFIX}:" \
	   			${BUILD_DIR}/Makefile
	use clip && cp "${FILESDIR}"/Xmessage "${BUILD_DIR}"/Xmessage.ad
}

