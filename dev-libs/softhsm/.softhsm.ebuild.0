# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit autotools eutils

DESCRIPTION="A software PKCS#11 implementation"
HOMEPAGE="http://www.opendnssec.org/"
SRC_URI="http://www.opendnssec.org/files/source/${P}.tar.xz"

# Create the archive:
# NAME="softhsm-2.0.0_alpha$(git log --date=short --pretty=format:%ad -1 | sed -e 's/-//g')"
# git archive "--prefix=${NAME}/" HEAD | xz > "../${NAME}.tar.xz"

KEYWORDS="~amd64 ~x86"
IUSE="debug clip-export"
SLOT="0"
LICENSE="BSD"

RDEPEND="
	dev-db/sqlcipher
	>=dev-libs/openssl-0.9.8
	!clip-export? ( >=dev-libs/libanssipki-crypto-2.0.0 )
	app-clip/fdp
"
DEPEND="${RDEPEND}"

DOCS=( NEWS README.md )

src_prepare() {
	epatch "${FILESDIR}/${P}-anssipki.patch"
	eautoreconf
}

src_configure() {
	econf \
		--disable-static \
		--with-openssl="${EPREFIX}${CPREFIX:-/usr}" \
		$(use clip-export || echo --with-anssipki="${EPREFIX}${CPREFIX:-/usr}") \
		--with-sqlcipher="${EPREFIX}${CPREFIX:-/usr}" \
		--with-objectstore-backend-db \
		--localstatedir="${EPREFIX}${CPREFIX:-/usr}" \
		$(use clip-export && echo --with-crypto-backend="openssl") \
		$(use clip-export || echo --with-crypto-backend="anssipki") \
		$(use debug && echo "--with-loglevel=4")
}

src_install() {
	default
	find "${ED}" -name '*.la' -delete
}
