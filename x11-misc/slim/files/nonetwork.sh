#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

XDIALOG_TITLE="Echec de configuration réseau"
XDIALOG_MSG="La configuration du réseau a échoué.\n\nIl ne sera pas possible d'accéder au réseau jusqu'à la correction du problème.\nSeuls les utilisateurs disposant des privilèges d'administration et/ou d'audit\npourront ouvrir une nouvelle session."
XDIALOG_HELP="CLIP n'a pas été en mesure de réaliser la configuration réseau nominale.\nLes causes probables de cet échec sont:\n- l'indisponibilité d'un serveur DHCP, si le système est configuré pour utiliser DHCP pour obtenir son addresse principale\n- l'indisponibilité d'un réseau Wifi, si le système est configuré pour utiliser un tel réseau\n- une erreur dans la configuration réseau.\nLa configuration réseau peut être corrigée depuis une session disposant des privilèges d'administration, par correction\net réactivation du profil réseau courant ou par activation d'un autre profil réseau."
XDIALOG_OK="Fermer"

if [[ -z "${XAUTHORITY}" ]]; then 
	export XAUTHORITY="/var/run/authdir/slim.auth"
fi
export DISPLAY=":0"
export LANG="fr_FR"
export LC_ALL="fr_FR"

/usr/local/bin/Xdialog \
	--title "${XDIALOG_TITLE}" --time-stamp --wrap --left \
	--ok-label "${XDIALOG_OK}" \
	--help "${XDIALOG_HELP}" --msgbox "${XDIALOG_MSG}" 0 0
