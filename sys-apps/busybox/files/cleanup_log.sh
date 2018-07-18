#!/bin/sh
# Copyright 2018 ANSSI
# Distributed under the terms of the GNU General Public License v2

cd /var/log || exit 1
for f in clip_*; do
	if [ -f "${f}" ]; then
		/bin/rm -f "${f}" || echo "Could not remove ${f}" >&2
	fi
done
