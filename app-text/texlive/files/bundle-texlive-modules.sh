#!/bin/sh
# Copyright 2011 SGDSN/ANSSI
# Author: Vincent Strubel <clipos@ssi.gouv.fr>
# Distributed under the terms of the GPL version 2.0

MODULE="${1}"
VERSION="${2}"
EBPATH="${3}"
INPATH="${4}"
OUTPATH="${5}"


EBUILD="${EBPATH}/${MODULE}/${MODULE}-${VERSION}.ebuild"
if [[ ! -f "${EBUILD}" ]]; then
	echo "Missing ${EBUILD}"
	exit 1
fi
source "${EBUILD}" 2>/dev/null
VERSION="${VERSION%%-*}"
MODDIR="${MODULE}-${VERSION}"
mkdir "/tmp/${MODDIR}"
pushd "/tmp/${MODDIR}"


MODS="${TEXLIVE_MODULE_CONTENTS}"
[[ -z "${MODULE##*documentation*}" ]] && MODS="${MODS} ${TEXLIVE_MODULE_DOC_CONTENTS}"

echo "Unpacking..."
for m in ${MODS}; do 
	echo " ...${m}"
	tar -Jxf "${INPATH}/texlive-module-${m}-${VERSION}.tar.xz"
done

echo "Creating archive..."
tar czf "${OUTPATH}/${MODDIR}.tar.gz" "."

popd 1>/dev/null
rm -fr "${MODDIR}"
echo "${OUTPATH}/${MODDIR}.tar.gz created"
