# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit eutils toolchain-funcs multilib multilib-minimal

DESCRIPTION="Http request/response parser for C"
HOMEPAGE="https://github.com/nodejs/http-parser"
SRC_URI="https://github.com/nodejs/http-parser/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/${PV}"
KEYWORDS="amd64 arm ~arm64 ppc ppc64 x86 ~amd64-linux ~x64-macos ~x64-solaris"
IUSE="static-libs"
IUSE="${IUSE} clip"

# https://github.com/nodejs/http-parser/pull/272
PATCHES=(
	"${FILESDIR}"/0001-makefile-fix-DESTDIR-usage.patch
	"${FILESDIR}"/0002-makefile-quote-variables.patch
	"${FILESDIR}"/0003-makefile-fix-SONAME-symlink-it-should-not-be-a-full-.patch
	"${FILESDIR}"/0004-makefile-add-CFLAGS-to-linking-command.patch
	"${FILESDIR}"/0005-makefile-fix-install-rule-dependency.patch
	"${FILESDIR}"/${PN}-2.6.2-darwin.patch
)

src_prepare() {
	tc-export CC AR
	epatch "${PATCHES[@]}"
	multilib_copy_sources
}

multilib_src_compile() {
	emake PREFIX="${EPREFIX}/usr" LIBDIR="${EPREFIX}/usr/$(get_libdir)" CFLAGS_FAST="${CFLAGS}" library
	use static-libs && emake CFLAGS_FAST="${CFLAGS}" package
}

multilib_src_test() {
	emake CFLAGS_DEBUG="${CFLAGS}" test
}

multilib_src_install() {
	# ajout de CPREFIX pour clip
	emake DESTDIR="${D}" PREFIX="${EPREFIX}${CPREFIX:-/usr}" LIBDIR="${EPREFIX}${CPREFIX:-/usr}/$(get_libdir)" install
	use static-libs && dolib.a libhttp_parser.a
}

# pour clip
multilib_src_install_all() {
	if (use clip); then
		rm -rf "${ED}${CPREFIX:-/usr}/share" || die "failed to delete ${D}${EPREFIX}${CPREFIX:-/usr}/share"
		rm -rf "${ED}${CPREFIX:-/usr}/include" || die "failed to delete ${D}${EPREFIX}${CPREFIX:-/usr}/include"
	fi
}
