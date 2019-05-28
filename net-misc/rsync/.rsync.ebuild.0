# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/net-misc/rsync/rsync-3.0.8.ebuild,v 1.6 2011/04/02 14:29:43 armin76 Exp $

inherit eutils flag-o-matic verictl2 deb

DESCRIPTION="File transfer program to keep remote files into sync"
DESCRIPTION_FR="Outil de synchronisation distante de fichiers"

HOMEPAGE="http://rsync.samba.org/"
SRC_URI="http://rsync.samba.org/ftp/rsync/src/${P/_/}.tar.gz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~hppa ~ia64 ~m68k ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~sparc-fbsd x86 ~x86-fbsd"
IUSE="acl iconv ipv6 static xattr clip clip-deps"

DEPEND=">=dev-libs/popt-1.5
	acl? ( virtual/acl )
	xattr? ( kernel_linux? ( sys-apps/attr ) )
	!clip-deps? ( iconv? ( virtual/libiconv ) )"

S=${WORKDIR}/${P/_/}

src_unpack() {
	unpack ${A}
	cd "${S}"

	epatch_user
}

src_compile() {
	use static && append-ldflags -static
	econf \
		--without-included-popt \
		$(use_enable acl acl-support) \
		$(use_enable xattr xattr-support) \
		$(use_enable ipv6) \
		$(use_enable iconv) \
		--with-rsyncd-conf=${CPREFIX}/etc/rsyncd.conf \
		|| die
	emake || die
}

src_install() {
	emake DESTDIR="${D}" install || die "make install failed"
	if ! use clip ; then
		newconfd "${FILESDIR}"/rsyncd.conf.d rsyncd
		newinitd "${FILESDIR}"/rsyncd.init.d rsyncd || die
		dodoc NEWS OLDNEWS README TODO tech_report.tex
		insinto /etc
		doins "${FILESDIR}"/rsyncd.conf || die
		
		insinto /etc/logrotate.d
		newins "${FILESDIR}"/rsyncd.logrotate rsyncd
		
		insinto /etc/xinetd.d
		newins "${FILESDIR}"/rsyncd.xinetd rsyncd
		
		# Install the useful contrib scripts
		exeinto /usr/share/rsync
		doexe support/* || die
		rm -f "${D}${CPREFIX:-/usr}"/share/rsync/{Makefile*,*.c}
	fi
}

pkg_postinst() {
	if egrep -qs '^[[:space:]]use chroot[[:space:]]*=[[:space:]]*(no|0|false)' \
		"${ROOT}"/etc/rsyncd.conf "${ROOT}"/etc/rsync/rsyncd.conf ; then
		ewarn "You have disabled chroot support in your rsyncd.conf.  This"
		ewarn "is a security risk which you should fix.  Please check your"
		ewarn "/etc/rsyncd.conf file and fix the setting 'use chroot'."
	fi
}

pkg_predeb() {
	if use clip ; then
	        doverictld2 "${CPREFIX:-/usr}/bin/rsync" e - - - cN ccsd
	fi
}
