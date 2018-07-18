#!/bin/sh

export DISPLAY=:0.0
export XAUTHORITY=$1
shift
export PATH=${PATH}:/usr/local/bin
export LANG="fr_FR"

setsid /usr/local/bin/notify-send "$@"
