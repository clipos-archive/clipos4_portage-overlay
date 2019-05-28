# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KDE_HANDBOOK="optional"
KDE_SELINUX_MODULE="gpg"
inherit kde4-base

DESCRIPTION="KDE gpg keyring manager"
HOMEPAGE="https://www.kde.org/applications/utilities/kgpg
https://utils.kde.org/projects/kgpg"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~amd64-linux ~x86-linux"
IUSE="debug clip"

DEPEND="
	$(add_kdeapps_dep kdepimlibs)
"
RDEPEND="${DEPEND}
	app-crypt/gnupg
"

pkg_postinst() {
	kde4-base_pkg_postinst

	if ! has_version app-crypt/dirmngr ; then
		elog "For improved key search functionality, install app-crypt/dirmngr."
	fi
}

src_install() {
	kde4-base_src_install
	
	if use clip; then
		local dir="${D}${CPREFIX:-/usr}/share/kde4/services/ServiceMenus"
		sed -i -e 's/Encrypt File/Encrypt File with GPG/' \
				-e 's/Chiffrer le fichier/Chiffrer le fichier avec GPG/' \
						"${dir}/encryptfile.desktop" || die 'sed file failed'
		sed -i -e 's/Encrypt Folder/Encrypt Folder with GPG/' \
				-e 's/Archiver puis chiffrer le dossier/Archiver puis chiffrer le dossier avec GPG/' \
						"${dir}/encryptfolder.desktop" || die 'sed folder failed'
	fi
}
