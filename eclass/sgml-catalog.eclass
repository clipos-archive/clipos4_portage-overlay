# Copyright 1999-2004 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/sgml-catalog.eclass,v 1.16 2010/06/16 03:36:06 abcd Exp $
#
# Author Matthew Turk <satai@gentoo.org>

inherit base deb

IUSE+=" clip"
DEPEND=">=app-text/sgml-common-0.6.3-r2"
RDEPEND="clip? ( >=app-text/sgml-common-0.6.3-r2 )"

# List of catalogs to install
SGML_TOINSTALL=""


sgml-catalog_cat_include() {
	debug-print function $FUNCNAME $*
	local arg1="${1}"
	local arg2="${2}"
	if [[ -n "${CPREFIX}" ]]; then
		if [[ "${arg1#/var}" == "${arg1}" && "${arg1#/}" != "${arg1}" ]]; then
			arg1="${CPREFIX}${arg1#/usr}" 
		fi
		if [[ "${arg2#/var}" == "${arg2}" && "${arg2#/}" != "${arg2}" ]]; then
			arg2="${CPREFIX}${arg2#/usr}" 
		fi
	fi
	SGML_TOINSTALL="${SGML_TOINSTALL} ${arg1}:${arg2}"
}

sgml-catalog_cat_doinstall() {
	debug-print function $FUNCNAME $*
	has "${EAPI:-0}" 0 1 2 && ! use prefix && EPREFIX=
	"${EPREFIX}"/usr/bin/install-catalog --add "${EPREFIX}$1" "${EPREFIX}$2" &>/dev/null
}

sgml-catalog_cat_doremove() {
	debug-print function $FUNCNAME $*
	has "${EAPI:-0}" 0 1 2 && ! use prefix && EPREFIX=
	"${EPREFIX}"/usr/bin/install-catalog --remove "${EPREFIX}$1" "${EPREFIX}$2" &>/dev/null
}

sgml-catalog_pkg_postinst() {
	debug-print function $FUNCNAME $*
	has "${EAPI:-0}" 0 1 2 && ! use prefix && EPREFIX=

	for entry in ${SGML_TOINSTALL}; do
		arg1=${entry%%:*}
		arg2=${entry#*:}
		if [ ! -e "${EPREFIX}"${arg2} ]
		then
			ewarn "${EPREFIX}${arg2} doesn't appear to exist, although it ought to!"
			continue
		fi
		einfo "Now adding ${EPREFIX}${arg2} to ${EPREFIX}${arg1} and ${EPREFIX}/etc/sgml/catalog"
		sgml-catalog_cat_doinstall ${arg1} ${arg2}
	done
	sgml-catalog_cleanup
}

sgml-catalog_pkg_prerm() {
	sgml-catalog_cleanup
}

sgml-catalog_pkg_postrm() {
	debug-print function $FUNCNAME $*
	has "${EAPI:-0}" 0 1 2 && ! use prefix && EPREFIX=

	for entry in ${SGML_TOINSTALL}; do
		arg1=${entry%%:*}
		arg2=${entry#*:}
		if [ -e "${EPREFIX}"${arg2} ]
		then
			ewarn "${EPREFIX}${arg2} still exists!  Not removing from ${EPREFIX}${arg1}"
			ewarn "This is normal behavior for an upgrade ..."
			continue
		fi
		einfo "Now removing ${EPREFIX}${arg1} from ${EPREFIX}${arg2} and ${EPREFIX}/etc/sgml/catalog"
		sgml-catalog_cat_doremove ${arg1} ${arg2}
	done
}

sgml-catalog_cleanup() {
	has "${EAPI:-0}" 0 1 2 && ! use prefix && EPREFIX=
	if [ -e "${EPREFIX}/usr/bin/gensgmlenv" ]
	then
		einfo Regenerating SGML environment variables ...
		gensgmlenv
		grep -v export "${EPREFIX}/etc/sgml/sgml.env" > "${EPREFIX}/etc/env.d/93sgmltools-lite"
	fi
}

sgml-catalog_src_compile() {
	return
}

sgml-catalog_deb_postinst() {
	debug-print function $FUNCNAME $*

	init_maintainer "postinst"
	cat >> "${D}/DEBIAN/postinst" <<EOF
set +e
SGML_TOINSTALL="${SGML_TOINSTALL}"
if [[ "\${1}" == "configure" || "\${1}" == "abort-remove" ]]; then
	for entry in \${SGML_TOINSTALL}; do
		arg1=\${entry%%:*}
		arg2=\${entry#*:}
		if [[ ! -e "\${arg2}" ]]; then
			echo "! SGML \${arg2} does not exist !" >&2
			continue
		fi
		${CPREFIX:-/usr}/bin/install-catalog --add "\${arg1}" "\${arg2}" &>/dev/null 
	done
fi
EOF
}

sgml-catalog_deb_postrm() {
	debug-print function $FUNCNAME $*

	init_maintainer "postrm"
	cat >> "${D}/DEBIAN/postrm" <<EOF
set +e
SGML_TOINSTALL="${SGML_TOINSTALL}"
if [[ "\${1}" == "remove" || "\${1}" == "upgrade" ]]; then
	for entry in \${SGML_TOINSTALL}; do
		arg1=\${entry%%:*}
		arg2=\${entry#*:}
		if [[ -e "\${arg2}" ]]; then
			if [[ "\${1}" != "upgrade" ]]; then
				echo "! SGML \${arg2} still exists !" >&2
			fi
			continue
		fi
		${CPREFIX:-/usr}/bin/install-catalog --remove "\${arg1}" "\${arg2}" &>/dev/null 
	done
fi
EOF
}

sgml-catalog_pkg_predeb() {
	ewarn "pkg_predeb: ${SGML_TOINSTALL}"
	debug-print function $FUNCNAME $*
	
	if [[ -n "${SGML_TOINSTALL}" ]]; then
		sgml-catalog_deb_postinst || die ""
		sgml-catalog_deb_postrm || die ""
	fi
}

EXPORT_FUNCTIONS pkg_postrm pkg_postinst src_compile pkg_prerm pkg_predeb
