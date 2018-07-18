#!/bin/sh
# Copyright 2011-2012 SGDSN/ANSSI
# Author: Vincent Strubel <clipos@ssi.gouv.fr>
# Distributed under the terms of the GNU General Public License v2

UPDATE_STR="Aucune information disponible sur la mise à jour des signatures antivirales."

get_update_date() {
	local sigfile="${HOME}/.clamav/daily.cld"
	if [[ ! -f "${sigfile}" ]]; then
		sigfile="${HOME}/.clamav/main.cld"
		[[ -f "${sigfile}" ]] || return 1
	fi

	local datetime="$(stat -c '%y' "${sigfile}" | awk -F '[ -:]' '{print $3"/"$2"/"$1" - "$4":"$5}')"

	UPDATE_STR="Dernière mise à jour des signatures antivirales : ${datetime}"
}

check_files() {
	local input
	for input in "${@}"; do 
		if [[ -f "${input}" ]]; then
			[[ "$(stat -c '%s' "${input}" 2>/dev/null)" != "0" ]] && return 0
		elif [[ -d "${input}" ]]; then
			for f in $(find "${input}" -type f -not -name '.*'); do
				[[ "$(stat -c '%s' "${f}" 2>/dev/null)" != "0" ]] && return 0
			done
		fi
	done
	return 1
}

if ! check_files "${@}"; then
	kdialog --title "Erreur" --error "Erreur: aucun fichier non vide à scanner"
	exit 1
fi

get_update_date

kdialog --title "Analyse antivirale" --msgbox "Analyse antivirale en cours, veuillez patienter.\n${UPDATE_STR}" &
PID=$!

CMD="clamscan --detect-broken -r"
[[ -e "${HOME}/.clamav/clamd.sock" ]] && CMD="clamdscan -m --fdpass"
LOG="$(${CMD} --infected --stdout --no-summary "${@}")"
kill $PID || kill -9 $PID
if [[ -n "${LOG}" ]]; then
	kdialog --title "Analyse antivirale" --error "Certains des fichiers analysés sont mailveillants :\n\n${LOG}"
	exit 1
else
	kdialog --title "Analyse antivirale" --msgbox "Aucun fichier malveillant n'a été trouvé.\n${UPDATE_STR}"
	exit 0
fi
