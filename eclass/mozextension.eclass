# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mozextension.eclass,v 1.9 2013/05/28 03:29:50 anarchy Exp $
#
# @ECLASS: mozextension.eclass
# @MAINTAINER:
# Mozilla team <mozilla@gentoo.org>
# @BLURB: Install extensions for use in mozilla products.


inherit eutils

DEPEND="app-arch/unzip"

mozversion_extension_location() {
	[[ "${MOZ_EXTENSION_TARGET}" == "firefox" ]] && return 0

	case ${PN} in
		firefox|firefox-bin)
			if [[ $(get_version_component_range 1) -ge 21 ]] ; then
				return 0
			fi
		;;
	esac

	return 1
}

xpi_unpack() {
	local xpi xpiname srcdir

	# Not gonna use ${A} as we are looking for a specific option being passed to function
	# You must specify which xpi to use
	[[ -z "$*" ]] && die "Nothing passed to the $FUNCNAME command. please pass which xpi to unpack"

	for xpi in "$@"; do
		einfo "Unpacking ${xpi} to ${PWD}"
		xpiname=$(basename ${xpi%.*})

		if   [[ "${xpi:0:2}" != "./" ]] && [[ "${xpi:0:1}" != "/" ]] ; then
			srcdir="${DISTDIR}/"
		fi

		[[ -s "${srcdir}${xpi}" ]] ||  die "${xpi} does not exist"

		case "${xpi##*.}" in
			ZIP|zip|jar|xpi)
				mkdir "${WORKDIR}/${xpiname}" && \
									   unzip -qo "${srcdir}${xpi}" -d "${WORKDIR}/${xpiname}" ||  die "failed to unpack ${xpi}"
				;;
			*)
				einfo "unpack ${xpi}: file format not recognized. Ignoring."
				;;
		esac
	done
}


xpi_install() {
	local emid

	# You must tell xpi_install which xpi to use
	[[ ${#} -ne 1 ]] && die "$FUNCNAME takes exactly one argument, please specify an xpi to unpack"

	x="${1}"
	cd ${x}

	# determine id for extension
	if [[ -n "${EMID}" ]]; then
		emid="${EMID}"
	else
		emid="$(perl -ne '/<\?xml/ and $p = 1; /<(:?!--)?(:?em:)?targetApplication>/ and $p = 0; /<\/(:?em:)?targetApplication>/ and $p=1; $p and /<?(:?em:)?id[>=]"?([^"<]+)"?(:?<\/(:?em:)?id>)?/ and print $2' "${x}"/install.rdf)"
	fi
	[[ -n "${emid}" ]] || die "failed to determine extension id"
	einfo "ID for extension: ${emid}"

	#emid="$(sed -n -e '/install-manifest/,$ { /em:id/!d; s/.*[\">]\([^\"<>]*\)[\"<].*/\1/; p; q }' "${x}"/install.rdf)" \
		#|| die "failed to determine extension id"

	if $(mozversion_extension_location) ; then
		insinto "${MOZILLA_FIVE_HOME}"/browser/extensions/${emid}
	else
		insinto "${MOZILLA_FIVE_HOME}"/extensions/${emid}
	fi
	doins -r "${x}"/* || die "failed to copy extension"
}

# CLIP:
jar_epatch() {
	[[ $# -lt 2 ]] && die "usage: jar_epatch <jar-file> <patch-1> [patch-N]"
	local name="$1"
	shift
	local patch
	local jardir="${WORKDIR}/${MY_P}/chrome"
	local jarfile="${jardir}/${name}"
	local tmpdir
	[[ -f "${jarfile}" ]] ||  die "File '${jarfile}' not found"
	tmpdir="$(mktemp -dp "${T}" "${name}-XXXXXXXXXX")" && \
		cd "${tmpdir}" && \
		unzip -q "${jardir}/${name}" ||  die "Failed to unpack ${name}"
	for patch in "$@"; do
		epatch "${patch}" || die
	done
	rm -- "${jardir}/${name}" || die "Failed to remove ${name}"
	zip -qr "${jardir}/${name}" * || die "Failed to pack ${name}"
}
