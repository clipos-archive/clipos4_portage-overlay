# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

inherit java-pkg-2 java-ant-2

DESCRIPTION="A desktop replacement for Microsoft Project. It is capable of sharing files with Microsoft Project and has very similar functionality (Gantt, PERT diagram, histogram, charts, reports, detailed usage), as well as tree views which aren't in MS Project"
DESCRIPTION_FR="Gestionnaire de projet compatible avec MS Project."
HOMEPAGE="http://www.openproj.org/openproj"
SRC_URI="mirror://sourceforge/openproj/openproj-${PV}-src.tar.gz"

LICENSE="CPL-1.0"

SLOT="0"
IUSE="clip"

KEYWORDS="~amd64 x86"

DEPEND=">=dev-java/sun-jdk-1.6
	>=virtual/jdk-1.6
	dev-java/ant-core"
RDEPEND="!clip? ( >=virtual/jdk-1.6 )
		clip? ( virtual/jre )"

S="${WORKDIR}/openproj-${PV}-src"

pkg_setup() {
	export JAVA_PKG_FORCE_VM="sun-jdk-1.6"
	java-pkg-2_pkg_setup
}

src_unpack() {
	unpack ${A}
	echo "JAVA_VM: ${JAVA_PKG_FORCE_VM} vs $(java-config -f)"
	cd "${S}/openproj_build/resources"

	epatch "${FILESDIR}/openproj-${PV}-fix-launcher.patch"

	if use clip; then
		epatch "${FILESDIR}/${PN}-1.4-clip.patch"
	fi
}

src_compile() {
	JAVA_ANT_ENCODING="UTF-8"

	cd "${S}/openproj_contrib"
	ant build-contrib build-script build-exchange build-reports

	JAVA_OPTS="-Xmx128m"
	java $JAVA_OPTS -jar ant-lib/proguard.jar @openproj_contrib.conf
	java $JAVA_OPTS -jar ant-lib/proguard.jar @openproj_script.conf
	java $JAVA_OPTS -jar ant-lib/proguard.jar @openproj_exchange.conf
	java $JAVA_OPTS -jar ant-lib/proguard.jar @openproj_exchange2.conf
	java $JAVA_OPTS -jar ant-lib/proguard.jar @openproj_reports.conf

	cd "${S}/openproj_build"
	ant -Dbuild_contrib=false
}

src_install() {
	local base="/usr/share"
	use clip && base="/usr/lib"
	java-pkg_jarinto "${base}/${PN}/lib/"
	java-pkg_dojar ${S}/openproj_build/dist/lib/*.jar

	java-pkg_jarinto "${base}/${PN}/"
	java-pkg_dojar ${S}/openproj_build/dist/${PN}.jar

	insinto "${base}/${PN}/"

	doins ${S}/openproj_build/resources/openproj.sh
	use clip && doins "${FILESDIR}/run.conf"
	fperms a+rx "${base}/${PN}/openproj.sh"
	dosym "${base}/${PN}/openproj.sh" /usr/bin/openproj

	doicon ${S}/openproj_build/resources/openproj.png
	if use clip; then
		domenu "${FILESDIR}"/openproj.desktop
		doicon "${FILESDIR}"/ms-project.png
		dodir "/usr/share/mime/packages"
		insinto "/usr/share/mime/packages"
		doins "${FILESDIR}"/openproj.xml
	else
		domenu ${S}/openproj_build/resources/openproj.desktop
	fi
}
