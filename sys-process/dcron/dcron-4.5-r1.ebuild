# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/sys-process/dcron/dcron-4.5.ebuild,v 1.8 2012/05/24 05:48:48 vapier Exp $

EAPI="2"

inherit cron toolchain-funcs eutils verictl2

DESCRIPTION="A cute little cron from Matt Dillon"
HOMEPAGE="http://www.jimpryor.net/linux/dcron.html http://apollo.backplane.com/FreeSrc/"
SRC_URI="http://www.jimpryor.net/linux/releases/${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 arm hppa ~ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh ~sparc x86"
IUSE="clip"

src_prepare() {
	epatch "${FILESDIR}"/${PN}-4.5-pidfile.patch
	epatch "${FILESDIR}"/${PN}-4.5-ldflags.patch
	tc-export CC
	cat <<-EOF > config
		PREFIX = /usr
		CRONTAB_GROUP = cron
	EOF
}

src_install() {
	emake install DESTDIR="${D}" || die
	dodoc CHANGELOG README "${FILESDIR}"/crontab

	docrondir
	docron crond -m0700 -o root -g wheel
	docrontab

	insinto /etc
	doins "${FILESDIR}"/crontab || die
	insinto /etc/cron.d
	doins extra/prune-cronstamps || die
	dodoc extra/run-cron extra/root.crontab

	if use clip; then
		newinitd "${FILESDIR}"/dcron.init.clip dcron || die
	else
		newinitd "${FILESDIR}"/dcron.init-4.5 dcron || die
	fi
		
	newconfd "${FILESDIR}"/dcron.confd-4.4 dcron

	if use !clip; then
		insinto /etc/logrotate.d
		newins extra/crond.logrotate dcron
	fi
}

pkg_postinst() {
	# upstream renamed their pid file
	local src="${ROOT}/var/run/cron.pid" dst="${ROOT}/var/run/crond.pid"
	if [ -e "${src}" -a ! -e "${dst}" ] ; then
		cp "${src}" "${dst}"
	fi
}

pkg_predeb() {
	cron_pkg_predeb
	doverictld2 "${CPREFIX:-/usr}/sbin/crond" Ier \
		'LINUX_IMMUTABLE' - 'LINUX_IMMUTABLE' -

	cat >> "${D}/DEBIAN/postinst" <<EOF
if [[ "\${1}" == "configure" || "\${1}" == "abort-remove" ]]; then
	rc-update add dcron default
fi

EOF
	cat >> "${D}/DEBIAN/prerm" <<EOF
if [[ "\${1}" == "remove" || "\${1}" == "upgrade" ]]; then
	rc-update del dcron
fi

EOF
}
