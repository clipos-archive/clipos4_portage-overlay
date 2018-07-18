# Copyright 1999-2014 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="4"

inherit eutils verictl2

DESCRIPTION="Fuse-filesystem utilizing the sftp service."
DESCRIPTION_FR="Utilitaire permettant le montage d'un répertoire distant à travers une connexion SSH"
CATEGORY_FR="Système de fichiers"
SRC_URI="mirror://sourceforge/fuse/${P}.tar.gz"
HOMEPAGE="http://fuse.sourceforge.net/sshfs.html"

LICENSE="GPL-2"
KEYWORDS="amd64 arm hppa ~ppc ~ppc64 x86 ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux"
SLOT="0"
IUSE="clip-deps clip clip-rm"

CDEPEND=">=sys-fs/fuse-2.6.0_pre3
	!clip-deps? ( >=dev-libs/glib-2.4.2 )"
RDEPEND="${DEPEND}
	>=net-misc/openssh-4.3"
DEPEND="${CDEPEND}
	virtual/pkgconfig"

src_prepare() {
	if use clip; then
		epatch "${FILESDIR}/${PN}-2.2-clip-sgid.patch"
		if use clip-rm; then
			epatch "${FILESDIR}/${PN}-2.2-clip-ssh-path.patch"
		else
			die "You need to create a ssh-path patch for your jail."
		fi
	fi
}

src_configure() {
	# hack not needed with >=net-misc/openssh-4.3
	econf --disable-sshnodelay
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	dodoc README NEWS ChangeLog AUTHORS FAQ.txt || die
	doman sshfs.1 || die
	if use clip; then
		chown 0:350 "${D}${CPREFIX:-/usr}/bin/sshfs"
		chmod 2755 "${D}${CPREFIX:-/usr}/bin/sshfs"
	fi
}

pkg_predeb() {
	doverictld2 ${CPREFIX:-/usr}/bin/sshfs e - - - f ccsd
}
