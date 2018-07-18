# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/virtual/jre/jre-1.6.0.ebuild,v 1.6 2008/01/18 01:40:58 ranger Exp $

DESCRIPTION="Virtual for JRE"
HOMEPAGE="http://java.sun.com/"
SRC_URI=""

LICENSE="as-is"
SLOT="1.6"
KEYWORDS="amd64 ~ppc ~ppc64 x86"
IUSE=""

RDEPEND="|| (
		=virtual/jdk-1.6.0*
		dev-java/icedtea6-bin
		=dev-java/icedtea-6*
		=dev-java/sun-jre-bin-1.6.0*
		=dev-java/ibm-jre-bin-1.6.0*
	)"
DEPEND=""
