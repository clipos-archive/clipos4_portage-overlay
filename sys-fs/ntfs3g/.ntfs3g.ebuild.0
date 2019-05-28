# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5
inherit eutils linux-info udev toolchain-funcs autotools verictl2

MY_PN=${PN/3g/-3g}
MY_P=${MY_PN}_ntfsprogs-${PV}

DESCRIPTION="Open source read-write NTFS driver that runs under FUSE"
HOMEPAGE="http://www.tuxera.com/community/ntfs-3g-download/"
SRC_URI="http://tuxera.com/opensource/${MY_P}.tgz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ppc ppc64 sparc x86 ~amd64-linux ~arm-linux ~x86-linux"
IUSE="acl debug +external-fuse ntfsdecrypt +ntfsprogs static-libs suid xattr"
IUSE="${IUSE} clip"

RDEPEND="!<sys-apps/util-linux-2.20.1-r2
	!sys-fs/ntfsprogs
	ntfsdecrypt? (
		>=dev-libs/libgcrypt-1.2.2:0
		>=net-libs/gnutls-1.4.4
	)
	external-fuse? ( >=sys-fs/fuse-2.8.0 )
	clip? ( >=clip-libs/clip-libvserver-4.1.1 )"
DEPEND="${RDEPEND}
	sys-apps/attr
	virtual/pkgconfig"

S="${WORKDIR}/${MY_P}"

DOCS="AUTHORS ChangeLog CREDITS README"

PATCHES=(
	"${FILESDIR}"/${PN}-2014.2.15-no-split-usr.patch
	"${FILESDIR}"/${PN}-2014.2.15-dont-put-things-in-root.patch
	"${FILESDIR}"/${P}-update-fuse-lite-to-support-ioctls.patch
	"${FILESDIR}"/${P}-implement-fstrim.patch
	"${FILESDIR}"/${P}-fix-fstrim-applied-to-partitons.patch
)

pkg_setup() {
	if use external-fuse && use kernel_linux; then
		if kernel_is lt 2 6 9; then
			die "Your kernel is too old."
		fi
		CONFIG_CHECK="~FUSE_FS"
		FUSE_FS_WARNING="You need to have FUSE module built to use ntfs-3g"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	epatch "${PATCHES[@]}"
	if use clip ; then 
		epatch "${FILESDIR}/${P}-clip-namespace.patch"
	fi
	eautoreconf
	elibtoolize
}

src_configure() {
	tc-ld-disable-gold
	econf \
		--prefix="${EPREFIX}"/usr \
		--exec-prefix="${EPREFIX}"/usr \
		--docdir="${EPREFIX}"/usr/share/doc/${PF} \
		$(use_enable debug) \
		--enable-ldscript \
		--disable-ldconfig \
		$(use_enable !clip mtab) \
		$(use_enable acl posix-acls) \
		$(use_enable xattr xattr-mappings) \
		$(use_enable ntfsdecrypt crypto) \
		$(use_enable ntfsprogs) \
		--without-uuid \
		--enable-extras \
		$(use_enable static-libs static) \
		--with-fuse=$(usex external-fuse external internal)
}

src_install() {
	dodir lib

	emake DESTDIR="${D}" install || die "install failed"

	dodoc AUTHORS ChangeLog CREDITS README

	use suid && fperms u+s /usr/bin/${MY_PN}

	if ! use clip; then
		udev_dorules "${FILESDIR}"/99-ntfs3g.rules
	fi
	prune_libtool_files

	dosym mount.ntfs-3g /usr/sbin/mount.ntfs #374197
}

pkg_predeb() {
	doverictld2 /usr/bin/ntfs-3g er 'CONTEXT|SYS_ADMIN' - 'CONTEXT|SYS_ADMIN' f ccsd
}
