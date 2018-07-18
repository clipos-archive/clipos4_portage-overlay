# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Id$

EAPI="5"
GST_ORG_MODULE=gst-plugins-good

inherit gstreamer

DESCRIPION="plugin to allow capture from video4linux2 devices"
KEYWORDS="alpha amd64 arm hppa ia64 ppc ppc64 sparc x86"
IUSE="udev"
IUSE+=" clip-devstation clip-livecd"

RDEPEND="
	>=media-libs/libv4l-0.9.5[${MULTILIB_USEDEP}]
	>=media-libs/gst-plugins-base-1.4:1.0[X,${MULTILIB_USEDEP}]
	udev? ( >=virtual/libgudev-208:=[${MULTILIB_USEDEP}] )
"
DEPEND="${RDEPEND}
	virtual/os-headers
	clip-devstation? ( =virtual/os-headers-0-r3 )
	clip-livecd? ( =virtual/os-headers-0-r3 )"

GST_PLUGINS_BUILD="gst_v4l2"

multilib_src_configure() {
	gstreamer_multilib_src_configure \
		--with-libv4l2 \
		$(use_with udev gudev)
}