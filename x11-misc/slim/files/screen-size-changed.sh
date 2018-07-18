#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

WP_PATH="/usr/local/share/wallpapers"
EXE="screen-size-changed"
WALLPAPER=""

get_wallpaper() {
	local w="${1}"
	local h="${2}"
	
	if [[ "${w}" == "${h}" ]]; then
		logger -p user.warning "${EXE}: invalid geometry: ${geom}, falling back to default wallpaper"
		WALLPAPER="${WP_PATH}/clip-16x9.png"
		return 0
	fi

	local fact=$(( ( 16 * $h ) / $w ))
	local wp="${WP_PATH}/clip-16x${fact}.png" 

	if [[ ! -e "${wp}" ]]; then
		# Possibly an extended screen - try halving the width
		w=$(( ${w} / 2 ))
		fact=$(( ( 16 * $h ) / $w ))
		wp="${WP_PATH}/clip-16x${fact}.png" 
	fi
		
	# Fall back to 16/9 as a last resort
	[[ -e "${wp}" ]] || wp="${WP_PATH}/clip-16x9.png"

	WALLPAPER="${wp}"
}

W="${1}"
H="${2}"
X="${3}"
Y="${4}"

[[ -n "${Y}" ]] || exit 0

logger -p user.info "${EXE}: new screen geometry - ${1}x${2}"

BPP="$(cat /sys/class/graphics/fb0/bits_per_pixel)"
[[ -z "${BPP}" ]] && BPP=32
umask="$(umask)"
umask 022
echo "${X}x${Y}:${BPP}" > "/etc/core/current.geom"
umask "${umask}"

CURRENT_USER="$(last -f /var/run/utmp | awk '$2 ~ /^:0/ { print $1 }' | head -n 1)"
[[ -n "${CURRENT_USER}" ]] || exit 0
CURRENT_UID=$(id -u ${CURRENT_USER})
[[ -n "${CURRENT_UID}" ]] || exit 0

get_wallpaper "${W}" "${H}"

if [[ -f "${WALLPAPER}" ]]; then
	vsctl user enter -u ${CURRENT_UID} -g 2000 \
		-e "XAUTHORITY=/home/user/.Xauthority%HOME=/home/user%DISPLAY=:0" -- \
		/usr/local/bin/feh --bg-scale --no-fehbg "${WALLPAPER}" 
fi

source /etc/conf.d/clip || exit 1
for jail in ${CLIP_JAILS}; do
	vsctl ${jail} enter -c /user -u ${CURRENT_UID} -g 2000 -- \
		/usr/local/bin/set-screen-size.sh "${X}" "${Y}"
done
