# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI=5

KMNAME="kde-runtime"
inherit kde4-meta pax-utils verictl2

DESCRIPTION="Command-line tool for network-transparent operations"
KEYWORDS="amd64 ~arm ppc ppc64 x86 ~x86-fbsd ~amd64-linux ~x86-linux"
IUSE="debug"

RESTRICT="test"


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
	doverictld2  ${KDEDIR}/bin/kioclient e - - - c
}

