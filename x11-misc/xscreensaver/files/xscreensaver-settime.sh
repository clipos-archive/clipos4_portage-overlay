#!/bin/sh
# xscreensaver-settime.sh : configure XscreenSaver timeout
# from a CLIP USER session
# Copyright (c) 2009-2010 SGDN/DCSSI
# Copyright (c) 2012-2013 SGDSN/ANSSI
# Authors: 
#    Vincent Strubel <clipos@ssi.gouv.fr>
#    Florent Chabaud <clipos@ssi.gouv.fr>
# Distributed under the terms of the GNU General Public License
# version 2.


error() {
	/usr/local/bin/Xdialog --no-cancel --center --msgbox \
		"Erreur de configuration du verrouillage de session:\n${1}" \
		0 0 
	exit 1
}

CONFIG="/home/user/.xscreensaver"
SOURCE="${CONFIG}"

increase()
{
	local tmout="${1}"
	local minstep="${2}"
	
	local tmhour="$(echo "${tmout}" | cut -d":" -f 1 | grep -Eoe '[0-9][0-9]')"
	[[ -z "${tmhour}" ]] && tmhour="00"
	local tmmin="$(echo "${tmout}" | cut -d":" -f 2 | grep -Eoe '[0-9][0-9]')"
	[[ -z "${tmmin}" ]] && tmmin="00"
	tmsec="$(echo "${tmout}" | cut -d":" -f 3 | grep -Eoe '[0-9][0-9]')"
	[[ -z "${tmsec}" ]] && tmsec="00"
	
	tmhour=$((1$tmhour - 10))
	[[ $tmhour -ge 90 ]] && tmhour=$(($tmhour - 90))
	[[ $tmhour -gt 23 ]] && tmhour=23
	tmmin=$((1$tmmin - 10))
	[[ $tmmin -ge 90 ]] && tmmin=$(($tmmin - 90))
	[[ $tmmin -gt 59 ]] && tmmin=59
	tmsec=$((1$tmsec - 10))
	[[ $tmsec -ge 90 ]] && tmsec=$(($tmsec - 90))
	[[ $tmsec -gt 59 ]] && tmsec=59
	
	tmhour=$(($tmhour + $minstep / 60))
	tmmin=$(($tmmin + $minstep % 60))
	tmhour=$(($tmhour + $tmmin / 60))
	tmmin=$(($tmmin % 60))
	[[ $tmhour -lt 10 ]] && tmhour="0${tmhour}"
	[[ $tmmin -lt 10 ]] && tmmin="0${tmmin}"
	[[ $tmsec -lt 10 ]] && tmsec="0${tmsec}"

	local ntmout="$(echo "${tmhour}:${tmmin}:${tmsec}" | grep -Eoe '[0-9][0-9]?:[0-5][0-9]:[0-5][0-9]')"
	echo "${ntmout}"
}

if [[ -r "${SOURCE}" ]]; then
	CURRENT_TMOUT="$(grep "timeout:" "${SOURCE}" | awk '{print $2}')"
else
	# first run
	CURRENT_TMOUT="00:10:00"
fi
NEW_TMOUT="$(increase "${CURRENT_TMOUT}" 0)"
[[ -z "${NEW_TMOUT}" ]] && exit 0

if [[ "$1" != "init" ]]; then
	CURRENT_TMHOUR="$(echo "${NEW_TMOUT}" | cut -d":" -f 1)"
	CURRENT_TMMIN="$(echo "${NEW_TMOUT}" | cut -d":" -f 2)"
	CURRENT_TMSEC="$(echo "${NEW_TMOUT}" | cut -d":" -f 3)"
	NEW_TMOUT=$(/usr/local/bin/Xdialog --title "Délai de verrouillage" \
		--stdout \
		--timebox "Veuillez définir le nouveau délai de verrouillage" \
		0 0 "${CURRENT_TMHOUR}" "${CURRENT_TMMIN}" "${CURRENT_TMSEC}")
fi

[[ -n "${NEW_TMOUT}" ]] || exit 0
	

echo "timeout: ${NEW_TMOUT}" > "${CONFIG}"
ret=$?
if [[ "$1" != "admin" ]]; then
	NEW_TMDPMS="${NEW_TMOUT}"
	echo "dpmsEnabled: true" >> "${CONFIG}"
	for dpms in Standby Suspend Off; do
		NEW_TMDPMS="$(increase "${NEW_TMDPMS}" 1)"
		[[ -n "${NEW_TMDPMS}" ]] && echo "dpms${dpms}: ${NEW_TMDPMS}" >> "${CONFIG}"
	done
		
	if [[ "$1" == "init" ]]; then
		/usr/local/bin/xset dpms force on
		/usr/local/bin/xset s off
		exit $ret
	fi
fi

[[ $ret -eq 0 ]] || error "Erreur d'écriture de la configuration"
/usr/local/bin/xscreensaver-command -restart
# No error here, will be picked up on next lock anyway, and seems
# to error out sometimes
# [[ $? -eq 0 ]] || error "Erreur de relecture de la configuration"

/usr/local/bin/Xdialog --no-cancel --center --title "Modification effectuée" \
	--msgbox "Le délai de verrouillage de session est désormais ${NEW_TMOUT}" \
	0 0
