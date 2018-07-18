# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-misc/read-edid/read-edid-2.0.0-r1.ebuild,v 1.3 2011/11/17 18:44:44 phajdan.jr Exp $

inherit pax-utils

DESCRIPTION="Program that can get information from a PnP monitor"
HOMEPAGE="http://www.polypux.org/projects/read-edid/"
SRC_URI="http://www.polypux.org/projects/${PN}/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* amd64 x86"
IUSE="clip-livecd"
DEPEND=">=dev-libs/libx86-1.1"
RDEPEND="${DEPEND}
		clip-livecd? ( >=sys-kernel/clip-kernel-3.2.13-r3 )"

src_compile() {
	econf --mandir=/usr/share/man || die "configure failed"
	emake || die "make failed"
}

src_install() {
	emake DESTDIR="${D}" install || die "emake install failed"
	use clip-livecd && pax-mark "m" "${D}/${CPREFIX:-/usr}/sbin/get-edid"
	# as per bug #283322
	dobin parse-edid || die "failed to install parse-edid binary"
	rm "${D}"/usr/sbin/parse-edid
	dodoc AUTHORS ChangeLog NEWS README
}
