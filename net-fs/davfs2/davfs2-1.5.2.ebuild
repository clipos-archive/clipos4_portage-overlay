# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

inherit user verictl2

DESCRIPTION="Linux FUSE (or coda) driver that allows you to mount a WebDAV resource"
DESCRIPTION_FR="Système de fichiers réseau basé sur WebDAV"
CATEGORY_FR="Système de fichiers"
HOMEPAGE="http://savannah.nongnu.org/projects/davfs2"
SRC_URI="http://mirror.lihnidos.org/GNU/savannah/davfs2/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="amd64 ppc x86"
IUSE="clip clip-deps"
RESTRICT="test"

DEPEND="dev-libs/libxml2
	net-libs/neon
	!clip-deps? ( sys-libs/zlib )"
RDEPEND="${DEPEND}"

pkg_setup() {
	enewgroup davfs2
}

src_prepare() {
	use clip && epatch "${FILESDIR}/${P}-clip.patch"
	eautoreconf
}

src_configure() {
	local conf=""
	local varrun="/var/run"
	local varcache="/var/cache"
	if use clip; then
		conf="--sbindir=${CPREFIX:-/usr}/bin"
		varrun="/tmp"
		varcache="/tmp"
	fi
	dav_localstatedir="${varrun}" dav_syscachedir="${varcache}" \
		econf dav_user=nobody --enable-largefile \
			--docdir="${CPREFIX:-/usr}"/share/doc/${P} ${conf}
}

src_install() {
	emake DESTDIR="${D}" install

	if use clip; then
		rm -fr "${D}/sbin" # silly hardcoded symlinks
		chown 0:350 "${D}${CPREFIX:-/usr}/bin/mount.davfs"
		chmod 2755 "${D}${CPREFIX:-/usr}/bin/mount.davfs"
	fi
}

pkg_postinst() {
	elog
	elog "Quick setup:"
	elog "   (as root)"
	elog "   # gpasswd -a \${your_user} davfs2"
	elog "   # echo 'http://path/to/dav /home/\${your_user}/dav davfs rw,user,noauto  0  0' >> /etc/fstab"
	elog "   (as user)"
	elog "   # mkdir -p ~/dav"
	elog "   \$ mount ~/dav"
	elog
}


pkg_predeb() {
	doverictld2  ${CPREFIX:-/usr}/bin/mount.davfs e - - - cf
}

