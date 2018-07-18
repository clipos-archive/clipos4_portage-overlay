#!/bin/sh
# clamscan.sh - manual update dialog for clamAV
# Copyright (C) 2011 SGDSN/ANSSI
# Author: Vincent Strubel <clipos@ssi.gouv.fr>
# Copyright 2018 ANSSI

error() {
	kdialog --title "Erreur" --error "${1}"
	exit 1
}

network_update() {
	local out="$(mktemp freshclam.XXXXXXXX)"
	[[ -n "${out}" ]] || error "Impossible de créer un fichier temporaire."

	freshclam -l "${out}" 
	if [[ $? -eq 0 ]]; then
		kdialog --title "Mise à jour effectuée" --yesno \
			"La mise à jour a été correctement effectuée. Souhaitez-vous visualiser les détails ?"
		if [[ $? -eq 0 ]]; then
			kdialog --title "Détails de mise à jour" \
				--textbox "${out}"
		fi
		rm -f "${out}"
		exit 0
	else
		error "Echec de la mise à jour par freshclam: code de retour $?."
	fi
}

usb_update() {
	local input=""
	input="$(kdialog --title "Veuillez sélectionner le fichier de signatures à importer" \
				--getopenfilename "/mnt/usb" "*.cld *.cvd")"
	[[ -n "${input}" ]] || exit 0

	mkdir -p "/home/user/.clamav"
	umask 0022
	cp "${input}" "/home/user/.clamav" 
	if [[ $? -eq 0 ]]; then
		kdialog --title "Mise à jour effectuée" --msgbox \
			"La mise à jour a été correctement effectuée."
		exit 0
	else
		error "La copie de la mise à jour a échoué."
	fi
}

TYPE="$(kdialog --title "Méthode de mise à jour" \
	--default "Clé USB" --combobox \
	"Veuillez sélectionner la méthode de mise à jour" \
	"Clé USB" "Réseau")"

[[ -n "${TYPE}" ]] || exit 0

case "${TYPE}" in
	Réseau)
		network_update
		;;
	*USB)
		usb_update
		;;
	*)
		error "Méthode non supportée : ${TYPE}."
		;;
esac
