#!/bin/sh
# Sound initialization init script for CLIP
# Copyright 2009 SGDN/DCSSI
# Copyright 2011 SGDSN/ANSSI
# Author: Vincent Strubel <clipos@ssi.gouv.fr>
#
# Distributed under the terms of the GNU General Public License v2

STATEDIR="/var/lib/alsa"

SYSPATH="/sys/class/sound/"

source "/lib/clip/devices.sub"
source "/lib/clip/import.sub"
source "/etc/conf.d/clip"

ADMIN_FILE="/etc/admin/conf.d/devices"
JAILS_IMPORT_FILTER="${CLIP_JAILS/ /|}"


make_carddevs() {
	local num="${1}"
	local ret=0

	make_sound_card_devices "${SYSPATH}/card${num}" "/dev" || ret=1
	for j in ${CLIP_JAILS}; do
		make_sound_card_devices "${SYSPATH}/card${num}" \
			"/mounts/vsdev/${j}/user_devs" || ret=1
	done
	
	return $ret
}


activate_sound_ctx() {
	local jail=
	local ret=0

	import_conf_noerr "${ADMIN_FILE}" "${JAILS_IMPORT_FILTER}" "SOUNDCARD0_JAIL" 2>/dev/null
	jail="${SOUNDCARD0_JAIL}"

	echo "    Sound card => ${jail}"
	/sbin/switch-sound-context "${jail}"
}

make_devs() {
	local num
	for num in ${SOUNDCARDS}; do
		make_carddevs "${num}"
	done
	activate_sound_ctx
}

remove_carddevs() {
	local num="${1}"
	local devpath=
	local ret=0

	for j in ${CLIP_JAILS}; do
		devpath="${devpath} /mounts/vsdev/${j}/user_devs"
	done

	for d in ${devpath} "/dev"; do
		for f in "${d}/snd/"/controlC* "${d}/snd"/pcmC*; do
			if [[ -c "${f}" ]]; then
				rm -f "${f}" || ret=1
			fi
		done
		for f in adsp audio dsp mixer snd/timer; do
			if [[ -c "${d}/${f}" ]]; then
				rm -f "${d}/${f}" || ret=1
			fi
		done
	done

	rm -f "${STATEDIR}/soundcard.jail"
	return $ret
}

remove_devs() {
	local num
	for num in ${SOUNDCARDS}; do
		remove_carddevs "${num}"
	done
}



init() {
	local jail
	local num
	local RET=0

	[[ -n "${SOUNDCARD0_JAIL}" ]] || return 0

	for num in ${SOUNDCARDS}; do
		alsactl init "${num}" 2>/dev/null
		RET=$(( $RET | $?))
	done
	case $RET in
		0)
			return 0
			;;
		99)	# Generic init
			return 0
			;;
		*)
			echo "Error initializing sound card ${num}" >&2
			return 1
			;;
	esac
}

[[ -d "/proc/asound" ]] || exit 0
SOUNDCARDS="$(sed -n -e 's/ *\([[:digit:]]*\) *\[.*/\1/p' /proc/asound/cards)"

RET=0
case "${1}" in
	start)
		# Cleanup any leftover devices
		remove_devs || exit 1
		make_devs || RET=1
		init || RET=1
		;;
	stop)
		remove_devs || RET=1
		;;
	*)
		echo "sound: Unsupported command ${1}"
		;;
esac

exit $RET
