#!/bin/sh


EXE="cellwriter"
ARGS="--keyboard-default --show-window"
EXE_PATH="/usr/local/bin"

[[ -z "${DISPLAY}" ]] && export DISPLAY=:0
RUNNING_UID=$(id -u)

if [[ "${RUNNING_UID}" == "0" ]]; then
	# Running from eventd so setup a bit the environment
	CURRENT_USER="$(last -f /var/run/utmp | awk '$2 ~ /^:0/ { print $1 }' | head -n 1)"

	if [[ -n "${CURRENT_USER}" ]]; then
		CURRENT_UID=$(id -u ${CURRENT_USER})
	fi
	
	if [[ -n "${CURRENT_UID}" ]]; then
		# User logged in
		exec vsctl user enter -d -u ${CURRENT_UID} --  "${0}" "${@}"
	else
		# We are at slim prompt
		[[ -z "$XAUTHORITY" ]] && export XAUTHORITY="/var/run/authdir/slim.auth"
		EXE="xvkbd"
		ARGS="-xdm -window root"
		${EXE_PATH}/xrdb -nocpp -merge /usr/local/share/X11/app-defaults/XVkbd-french
		${EXE_PATH}/xrdb -nocpp -merge /usr/local/etc/XVkbd.resources
	fi
else
	[[ -z "$XAUTHORITY" ]] && export XAUTHORITY="/home/user/.Xauthority"
fi


case $1 in
	1|on|enable|start)
		pgrep ${EXE} >/dev/null || ${EXE_PATH}/${EXE} ${ARGS} &
		;;
	0|off|disable|stop)
		pkill ${EXE}
		;;
	*)
		pkill ${EXE} || ${EXE_PATH}/${EXE} ${ARGS} &
		;;
esac
