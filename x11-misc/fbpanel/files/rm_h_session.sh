#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

SERVER=rm_h
VIEWER_ROOT="/viewers/${SERVER}"
REQUEST_SOCKET="${VIEWER_ROOT}/vserver/run/start"
VNC_SOCKET="${VIEWER_ROOT}/vserver/run/vnc/vnc1"
NEW_AUTH="/xauth/${SERVER}/xauthority"

get_screen_geom() {
	local gfile="/etc/core/screen.geom"
	[[ -f "/etc/core/current.geom" ]] && gfile="/etc/core/current.geom" 
	local geom="$(cat "${gfile}")"
	[[ -n "${geom}" ]] || exit 1
	local geomx="${geom%x*}"
	local geomy="${geom#*x}"
	geomy="${geomy%:*}"

	case "$(cat /var/run/viewmode)" in
	fullscreen)
		GEOMX=${geomx}
		GEOMY=${geomy}
		;;
	mix)
		GEOMX=$(expr ${geomx} - 32 )
		GEOMY=${geomy}
		;;
	*)
		GEOMX=$(expr ${geomx} - 6 )
		GEOMY=$(expr ${geomy} - 60 )
		;;
	esac
}

clean_exit() {
	test -f "${NEW_AUTH}" || exit 0
	for i in $(seq 5); do
		if test -f "${NEW_AUTH}"; then 
			rm -f "${NEW_AUTH}" || sleep 2
		else 
			exit 0
		fi
	done
	exit 1
}

let "num=0"
for p in /proc/*/cmdline; do
	cat "${p}" | grep -v autostart | grep -q rm_h_session.sh && let "num+=1"
done
if [[ ${num} -gt 1 ]]; then
	echo "rm_h_session.sh already active, exiting" >&2
	exit 0
fi

trap "clean_exit" SIGINT SIGQUIT SIGHUP SIGTERM SIGPIPE SIGCHLD || exit 1

trap

# test for socket presence
# (could be leftover from e.g. crashed session)
if test -e "${VNC_SOCKET}"; then
	if test ! -S "${VNC_SOCKET}"; then
		echo "${VNC_SOCKET} is not a socket, aborting" > /dev/stderr
		exit 1
	else
		LEFTOVER_SOCKET="y"
	fi
fi


get_screen_geom

jailrequest "${REQUEST_SOCKET}" || exit 1


if test -f "${NEW_AUTH}"; then 
	# exit immediately if we can't remove an older
	# Xauth file - no point waiting for xauth to
	# time out
	rm -f "${NEW_AUTH}" || exit 1
fi
if test -e "${NEW_AUTH}"; then
	# careful with links, etc
	exit 1
fi
xauth -f "${NEW_AUTH}" generate "${DISPLAY}" . domain 2

viewer-launch "/${SERVER}" /bin/viewer.sh "Visionneuse RM_H" \
			${GEOMX}x${GEOMY} ${LEFTOVER_SOCKET} 


clean_exit 
exit 0

