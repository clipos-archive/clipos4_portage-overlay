# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-irc/konversation/konversation-1.4.ebuild,v 1.1 2011/12/08 10:36:28 johu Exp $

EAPI=5
KDE_LINGUAS="bg bs ca ca@valencia cs da de el en_GB es et fi fr gl hu it ja nb
nds nl pl pt pt_BR ru si sr sr@ijekavian sr@ijekavianlatin sr@latin sv tr uk
zh_CN zh_TW"
KDE_DOC_DIRS="doc doc-translations/%lingua_${PN}"
KDE_HANDBOOK="optional"
inherit kde4-base verictl2

MY_PV="${PV/_/-}"
MY_P="${PN}-${MY_PV}"
DESCRIPTION="A user friendly IRC Client for KDE4"
DESCRIPTION_FR="Client de messagerie instantanée IRC"
CATEGORY_FR="Réseau"

HOMEPAGE="http://konversation.kde.org"
SRC_URI="mirror://kde/stable/${PN}/${MY_PV}/src/${MY_P}.tar.xz"

LICENSE="GPL-2 FDL-1.2"
SLOT="4"
KEYWORDS="~amd64 x86"
IUSE="+crypt debug"

DEPEND="
	$(add_kdeapps_dep kdepimlibs)
	crypt? ( app-crypt/qca:2 )
"

RDEPEND="${DEPEND}
	crypt? ( app-crypt/qca-ossl )
"

DOCS="AUTHORS ChangeLog NEWS README TODO"

S="${WORKDIR}/${MY_P}"

src_configure() {
	mycmakeargs+=(
		$(cmake-utils_use_with crypt QCA2)
	)
	kde4-base_src_configure
}

pkg_predeb() {
	doverictld2  ${CPREFIX:-/usr}/bin/konversation e - - - c
}
