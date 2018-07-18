#!/bin/bash -e

# expand-xdg-icons.sh - Get or create symlinks for XDG icons
# Copyright 2012 ANSSI
# Author: Mickaël Salaün <clipos@ssi.gouv.fr>
#
# Distributed under the terms of the GNU General Public License v2

build_db() {
	local root="$1"
	[ -d "${root}" ]
	local target link
	pushd "${root}" >/dev/null
	find -type l | while read link; do
		target="$(readlink -- "${link}")"
		target="${target%.*}"
		link="$(basename -- "$(dirname -- "${link}")")/$(basename -- "${link}")"
		link="${link%.*}"
		echo "${link}	${target}"
	done | sort -u
	popd >/dev/null
}

clean_db() {
	local root="$1"
	[ -d "${root}" ]
	local db="$2"
	db="$(readlink -f -- "${db}")"
	[ -f "${db}" ]
	local target icon
	pushd "${root}" >/dev/null
	find ! -type d | while read icon; do
		icon="$(basename -- "$(dirname -- "${icon}")")\\/$(basename -- "${icon}")"
		icon="${icon%.*}"
		sed -i -e "/^${icon}/d" "${db}"
	done
	popd >/dev/null
}

link_db() {
	local root="$1"
	[ -d "${root}" ]
	local dst target link targetpath targetfile ext
	pushd "${root}" >/dev/null
	while read link target; do
		find -type d -name "$(dirname -- "${link}")" | while read linkdir; do
			link="${linkdir}/$(basename -- "${link}")"
			targetpath="${linkdir}/${target}"
			for targetfile in "${targetpath}".*; do
				if [ -f "${targetfile}" ]; then
					ext="${targetfile##*.}"
					if [ ! -e "${link}.${ext}" ]; then
						ln -s -- "${target}.${ext}" "${link}.${ext}"
					fi
				fi
			done
		done
	done
	popd >/dev/null
}

CMD="$1"
case "${CMD}" in
	build)
		build_db "$2"
		;;
	clean)
		clean_db "$2" "$3"
		;;
	link)
		link_db "$2"
		;;
	*)
		echo "usage: $0 { build <icon-dir-ref> > DB.TXT | clean <icon-dir-to-verify> <db.txt> | link <icon-dir-to-fix> < DB.TXT }" >&2
		echo "  * build: record symlinks [on the source] (e.g. Oxymentary + Debian)" >&2
		echo "  * clean: remove duplicates [on the target]" >&2
		echo "  * link: create symlinks [on the target]" >&2
		;;
esac
