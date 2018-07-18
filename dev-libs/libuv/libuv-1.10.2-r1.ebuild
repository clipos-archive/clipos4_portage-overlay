# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# clip : change eapi from 6 to 5
EAPI=5

inherit autotools eutils multilib-minimal

DESCRIPTION="Cross-platform asychronous I/O"
HOMEPAGE="https://github.com/libuv/libuv"
SRC_URI="https://github.com/libuv/libuv/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="BSD BSD-2 ISC MIT"
SLOT="0/1"
KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~mips ppc ppc64 sparc x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"

IUSE="static-libs"
IUSE="${IUSE} clip"

RESTRICT="test"

DEPEND="sys-devel/libtool
	virtual/pkgconfig[${MULTILIB_USEDEP}]"


src_prepare() {
	default

	echo "m4_define([UV_EXTRA_AUTOMAKE_FLAGS], [serial-tests])" \
		> m4/libuv-extra-automake-flags.m4 || die

	eautoreconf
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" econf \
		cc_cv_cflags__g=no \
		$(use_enable static-libs static)
}

multilib_src_test() {
	mkdir "${BUILD_DIR}"/test || die
	cp -pPR "${S}"/test/fixtures "${BUILD_DIR}"/test/fixtures || die
	default
}

multilib_src_install_all() {
	if (use clip); then
		rm -rf "${ED}${CPREFIX-:/usr}/include"
	else
		einstalldocs
	fi

	prune_libtool_files
}

