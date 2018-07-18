# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
DECLARATIVE_REQUIRED="always"
EGIT_BRANCH="KDE/4.13"

inherit kde4-base

DESCRIPTION="KDE Activity Manager"

KEYWORDS=" ~amd64 ~arm ~ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="minimal"

DEPEND=""
RDEPEND="${DEPEND}
	!<kde-base/kdelibs-4.9.0
	!<kde-base/kdebase-runtime-4.9.0"


# Split out from kdelibs in 4.7.1-r2
#add_blocker kdelibs 4.7.1-r1
# Moved here in 4.8
#add_blocker activitymanager

src_configure() {
	local mycmakeargs=(
	        -DWITH_NepomukCore=OFF
			        $(cmake-utils_use minimal KACTIVITIES_LIBRARY_ONLY)
	)
	kde4-base_src_configure
}
