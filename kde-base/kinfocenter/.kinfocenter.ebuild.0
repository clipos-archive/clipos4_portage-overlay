# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KDE_HANDBOOK="optional"
KMNAME="kde-workspace"
OPENGL_REQUIRED="optional"
inherit kde4-meta

DESCRIPTION="The KDE Info Center"
HOMEPAGE="https://www.kde.org/applications/system/kinfocenter/"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="debug ieee1394 clip"

DEPEND="
	sys-apps/pciutils
	x11-libs/libX11
	ieee1394? ( sys-libs/libraw1394 )
	opengl? (
		virtual/glu
		virtual/opengl
	)
"
RDEPEND="${DEPEND}
	sys-apps/usbutils
"
src_prepare() {

	kde4-meta_src_prepare
	if use clip; then
	   epatch "${FILESDIR}/kdebase-workspace-4.9.4-clip-cprefix.patch"
	fi
}

src_configure() {
	local mycmakeargs=(
		$(cmake-utils_use_with ieee1394 RAW1394)
		$(cmake-utils_use_with opengl OpenGL)
	)

	kde4-meta_src_configure
}
