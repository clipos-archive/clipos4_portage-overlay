#!/bin/sh

if ! /usr/local/bin/xscreensaver-command -lock; then
	/usr/local/bin/xscreensaver &
	/usr/local/bin/xscreensaver-command -lock
fi
