# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/os-headers/os-headers-0.ebuild,v 1.6 2012/04/26 14:32:12 aballier Exp $

EAPI=1

DESCRIPTION="Virtual for operating system headers"
HOMEPAGE=""
SRC_URI=""

LICENSE=""
SLOT="0"
KEYWORDS="alpha amd64 arm hppa ia64 m68k ~mips ppc ppc64 s390 sh sparc x86 ~ppc-aix ~amd64-fbsd ~sparc-fbsd ~x86-fbsd ~x64-freebsd ~x86-freebsd ~hppa-hpux ~ia64-hpux ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris"
IUSE="clip-devstation clip-livecd"

DEPEND=""
# depend on SLOT 0 of linux-headers, because kernel-2.eclass
# sets a different SLOT for cross-building
RDEPEND="
	|| (
		kernel_linux? (
			sys-kernel/linux-headers:0
			clip-devstation? ( ~sys-kernel/linux-headers-4.4 )
			clip-livecd? ( ~sys-kernel/linux-headers-4.4 )
		)
		!prefix? ( sys-freebsd/freebsd-lib )
	  )"
