#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

VNC_SOCKET="/vserver/run/vnc/vnc1"
VNC_PASSWD="/vserver/run/vncpasswd"

VIEWER_TITLE=$1
LEFTOVER_SOCKET=$3

# Wait for jail-side Xvnc to create it's socket
# Note : we can't help with leftover sockets, as 
# we don't want a host-side removal of an untrusted guest file...
wait_socket() {
	#if there is a leftover socket, wait a generic delay
	if test $LEFTOVER_SOCKET ; then
		echo "Warning : leftover VNC socket"
		echo "Will try to continue anyway in a few secs"
		sleep 5
		return 0
	fi
	#else loop a few times looking for socket 
	for i in 1 2 3 4 5; do
		if test -e $VNC_SOCKET; then
			return 0;
		else
			sleep 2
		fi
	done
}

test -z "$VIEWER_TITLE" && exit 1

export DISPLAY=:0

export XAUTHORITY=/xauth/xauthority

wait_socket || exit 1

/bin/vncviewer "${VNC_SOCKET}" -ViewerTitle "${VIEWER_TITLE}" -PasswordFile "${VNC_PASSWD}" \
	-PreferredEncoding=Raw -SendClipboard=0 -AcceptClipboard=0 -DesktopSize=1 -FullColor=1

rm -f ${XAUTHORITY}
