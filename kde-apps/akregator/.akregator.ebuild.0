# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

KDE_HANDBOOK="optional"
KMNAME="kdepim"
EGIT_BRANCH="KDE/4.14"
inherit kde4-meta

DESCRIPTION="KDE news feed aggregator"
DESCRIPTION_FR="Lecteur de flux RSS/Atom"
HOMEPAGE="https://www.kde.org/applications/internet/akregator"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="debug"

DEPEND="
	$(add_kdeapps_dep kdepimlibs)
	$(add_kdeapps_dep kdepim-common-libs)
"
RDEPEND="${DEPEND}"

KMLOADLIBS="kdepim-common-libs"

#CLIP
pkg_predeb() {
	doverictld2  ${CPREFIX:-/usr}/bin/akregator e - - - c
	}
