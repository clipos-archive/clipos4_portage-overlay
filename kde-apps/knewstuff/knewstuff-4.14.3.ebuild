# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KMNAME="kde-runtime"
inherit kde4-meta pax-utils verictl2

DESCRIPTION="KDE4 software to download and upload 'new stuff'"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="debug"
RESTRICT="test"

#KMNOMODULE="true"

KMEXTRACTONLY="
    config-runtime.h.cmake
	kde4
"

src_configure() {
		mycmakeargs=(
				-DWITH_SLP=OFF
				-DKDEBASE_KGLOBALACCEL_REMOVE_OBSOLETE_KDED_DESKTOP_FILE=NOTFOUND
				-DKDEBASE_KGLOBALACCEL_REMOVE_OBSOLETE_KDED_PLUGIN=NOTFOUND
				-DBUILD_tests=OFF
				-DWITH_Xine=OFF
				$(cmake-utils_use_with alsa)
				$(cmake-utils_use_with pulseaudio PulseAudio)
				$(cmake-utils_use_with bzip2 BZip2)
				$(cmake-utils_use_with exif Exiv2)
				$(cmake-utils_use_with lzma LibLZMA)
				$(cmake-utils_use_with openexr OpenEXR)
				$(cmake-utils_use_with samba)
				$(cmake-utils_use_with sftp LibSSH)
				$(cmake-utils_use_find_package semantic-desktop Gpgme)
				$(cmake-utils_use_find_package semantic-desktop QGpgme)
				)

				kde4-meta_src_configure
}

pkg_predeb() {
	doverictld2  ${KDEDIR}/bin/khotnewstuff4 e - - - c
}
