# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/xfce-base/xfce4-meta/xfce4-meta-4.10.ebuild,v 1.6 2012/05/22 05:43:29 jdhore Exp $

EAPI=4

DESCRIPTION="The Xfce Desktop Environment (meta package)"
DESCRIPTION_FR="Environnement de bureau Xfce (alternative a KDE)"
CATEGORY_FR="Environnements de bureau"
HOMEPAGE="http://www.xfce.org/"
SRC_URI=""

LICENSE="as-is"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm hppa ~ia64 ~mips ppc ppc64 ~sparc x86 ~x86-fbsd ~x86-freebsd ~x86-interix ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="minimal +svg clip"

RDEPEND=">=x11-themes/gtk-engines-xfce-3:0
	x11-themes/hicolor-icon-theme
	>=xfce-base/xfce4-appfinder-4.10
	>=xfce-base/xfce4-panel-4.10
	>=xfce-base/xfce4-session-4.10
	>=xfce-base/xfce4-settings-4.10
	>=xfce-base/xfdesktop-4.10
	>=xfce-base/xfwm4-4.10
	clip? ( 
		x11-themes/tango-icon-theme
		x11-terms/xfce4-terminal
		xfce-extra/xfce4-mixer
		!x11-terms/terminal
	)
	!minimal? (
		media-fonts/dejavu
		virtual/freedesktop-icon-theme
		)
	svg? ( gnome-base/librsvg )"
