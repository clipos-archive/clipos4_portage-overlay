# Copyright 1999-2010 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/gnome-base/gnome-keyring/gnome-keyring-2.28.2.ebuild,v 1.6 2010/08/18 22:06:45 maekke Exp $

EAPI="2"

inherit gnome2 pam virtualx eutils autotools libtool deb pax-utils verictl2

DESCRIPTION="Password and keyring managing daemon"
HOMEPAGE="http://www.gnome.org/"

LICENSE="GPL-2 LGPL-2"
SLOT="0"
KEYWORDS="alpha amd64 arm ia64 ~mips ~ppc ~ppc64 sh sparc x86 ~x86-fbsd"
IUSE="debug doc pam test clip clip-rm clip-core rm-deps"
# USE=valgrind is probably not a good idea for the tree

RDEPEND="!rm-deps? ( >=dev-libs/glib-2.16 )
	!clip? ( 
		>=x11-libs/gtk+-2.6 
		gnome-base/gconf
		>=sys-apps/dbus-1.0
	)
	clip-core? ( clip-libs/clip-libvserver )
	pam? ( virtual/pam )
	>=dev-libs/libgcrypt-1.2.2
	>=dev-libs/libtasn1-1"
#	valgrind? ( dev-util/valgrind )"
DEPEND="${RDEPEND}
	sys-devel/gettext
	>=dev-util/intltool-0.35
	>=dev-util/pkgconfig-0.9
	>=x11-libs/gtk+-2.6 
	gnome-base/gconf
	dev-libs/dbus-glib
	doc? ( >=dev-util/gtk-doc-1.9 )"

DOCS="AUTHORS ChangeLog NEWS README TODO keyring-intro.txt"

pkg_setup() {
	use clip-core && CLIP_CONF_FILES="/etc/conf.d/p11proxy"

	G2CONF="${G2CONF}
		$(use_enable debug)
		$(use_enable pam)
		$(use_with pam pam-dir $(getpam_mod_dir))
		--with-root-certs=/usr/share/ca-certificates/
		--disable-schemas-install
		$(use_enable !clip acl-prompts)
		$(use_enable !clip ssh-agent)"
#		$(use_enable valgrind)
}

src_prepare() {
	gnome2_src_prepare

	# Remove silly CFLAGS
	sed 's:CFLAGS="$CFLAGS -Werror:CFLAGS="$CFLAGS:' \
		-i configure.in configure || die "sed failed"

	if use clip; then
		epatch "${FILESDIR}/clip_p11proxy.patch"
		eautoreconf
		elibtoolize
	fi
}

src_configure() {
	econf ${G2CONF} || die "configure failed"
}

src_install() {
	if use clip-core; then
		make
		exeinto /usr/sbin
		newexe "${S}"/pkcs11/rpc-layer/gck-rpc-daemon-standalone p11proxy
		doinitd "${FILESDIR}"/pk11proxy

		local ctx="505"
		for jail in rm_b rm_h core ; do
		    insinto "/etc/jails/p11proxy_${jail}"
		    doins "${FILESDIR}"/jails/p11proxy/*
		    echo "/var/lib/p11proxy_${jail}" > "${D}/etc/jails/p11proxy_${jail}/root"
		    echo "${ctx}" > "${D}/etc/jails/p11proxy_${jail}/context"
		    dodir "/var/lib/p11proxy_${jail}/var/run/pcscd"
		    dodir "/var/lib/p11proxy_${jail}/usr/lib"
			dodir "/dev"
			dodir "/sys"
		    ctx=$((${ctx}+1))
		done

		insinto /etc/conf.d/
		doins "${FILESDIR}"/conf/p11proxy

		exeinto /usr/lib
		newexe "${S}"/pkcs11/rpc-layer/.libs/gnome-keyring-pkcs11.so p11proxy.so

	elif use clip-rm; then
		make
		exeinto /usr/lib
		newexe "${S}"/pkcs11/rpc-layer/.libs/gnome-keyring-pkcs11.so p11proxy.so
	else
		make DESTDIR="${D}" install || die "make install failed"
	fi
}

src_test() {
	unset DBUS_SESSION_BUS_ADDRESS
	Xemake check || die "emake check failed!"
}

pkg_predeb() {
	if use clip-core; then
		doverictld2 /usr/sbin/p11proxy er \
			'CONTEXT|SYS_ADMIN' 'CONTEXT|SYS_ADMIN' - -
		init_maintainer "prerm"
		cat >> "${D}/DEBIAN/prerm" << ENDSCRIPT
/sbin/rc-update -d pk11proxy
ENDSCRIPT
		init_maintainer "postinst"
		cat >> "${D}/DEBIAN/postinst" << ENDSCRIPT
/sbin/rc-update -a pk11proxy default
ENDSCRIPT
	fi
}
