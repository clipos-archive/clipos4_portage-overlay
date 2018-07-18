#!/bin/sh
# Distributed under the terms of the GNU General Public License v2

# Allow the user to override command-line flags, bug #357629.
# This is based on Debian's chromium-browser package, and is intended
# to be consistent with Debian.
if [ -f /usr/local/etc/chromium/default ] ; then
	. /usr/local/etc/chromium/default
fi

# Prefer user defined CHROMIUM_USER_FLAGS (from env) over system
# default CHROMIUM_FLAGS (from /etc/chromium/default).
CHROMIUM_FLAGS=${CHROMIUM_USER_FLAGS:-"$CHROMIUM_FLAGS"}

# Load all extensions in /usr/local/lib/chromium-browser/extensions/
EXTS=""
for ext in /usr/local/lib/chromium-browser/extensions/*; do
  [[ -d "${ext}" ]] && EXTS="${EXTS}${ext},"
done
CHROMIUM_FLAGS="${CHROMIUM_FLAGS} --load-extension=${EXTS%,}"

# Let the wrapped binary know that it has been run through the wrapper
export CHROME_WRAPPER="`readlink -f "$0"`"

PROGDIR="`dirname "$CHROME_WRAPPER"`"

case ":$PATH:" in
  *:$PROGDIR:*)
    # $PATH already contains $PROGDIR
    ;;
  *)
    # Append $PROGDIR to $PATH
    export PATH="$PATH:$PROGDIR"
    ;;
esac

# Set the .desktop file name
export CHROME_DESKTOP="chromium-browser-chromium.desktop"

# Needed for flash, etc
export LD_LIBRARY_PATH="/usr/local/lib"

exec "$PROGDIR/chrome" --extra-plugin-dir=/usr/local/lib/nsbrowser/plugins ${CHROMIUM_FLAGS} "$@"
