#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

machine="$(cat /etc/core/machine)"

rm -f /usr/local/etc/X11/xorg.conf

conf=""

if [[ -e "/etc/shared/video" ]]; then
	conf="$(cat /etc/shared/video | head -n 1)"
fi

if [[ -z "${conf}" ]]; then 
	case ${machine} in 
		DELL_Latitude_D420)
			conf="intel"
			;;
		DELL_Latitude_D430)
			conf="intel"
			;;
		DELL_Latitude_D520)
			conf="intel"
			;;
		DELL_Latitude_D530)
			conf="intel"
			;;
		DELL_Latitude_E4300)
			conf="intel"
			;;
		DELL_Latitude_E5500)
			conf="intel"
			;;
		LENOVO_Thinkpad_X60)
			conf="intel"
			;;
		LENOVO_Thinkpad_X61)
			conf="intel"
			;;
		LENOVO_Thinkpad_X200)
			conf="intel"
			;;
		LENOVO_Thinkpad_R500)
			conf="intel"
			;;
		*)
			conf="vesa"
			;;
	esac
fi

[[ "${conf}" == "vesa" ]] && conf="fbdev"
[[ "${conf}" == "nvidia" ]] && conf="nouveau"

echo " * Updating xorg.conf to xorg.conf.${conf}"

ln -sf /usr/local/etc/X11/xorg.conf.${conf} /usr/local/etc/X11/xorg.conf
