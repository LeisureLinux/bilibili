#!/bin/bash
# vim: set sts=4 sw=4 et tw=0 :
#
# License: BSD
# set -x
# Original Author: https://gist.github.com/nirbheek/5589105

AUTOMAGIC_MODE="true"
OPACITY_100="0xffffffff"
OPACITY_0="0x0"

: ${XWININFO:=$(type -P xwininfo)}
[[ -z ${XWININFO} ]] && {
	echo "You need to install xwininfo"
	exit 1
}
: ${XPROP:=$(type -P xprop)}
[[ -z ${XPROP} ]] && {
	echo "You need to install xprop"
	exit 1
}

TRANSPARENCY_PERCENT=$1
[[ -z "${TRANSPARENCY_PERCENT}" ]] && {
	echo "Usage: $0 <transparency in percentage>"
	exit 1
}

if [[ ${AUTOMAGIC_MODE} != true ]]; then
	echo "Click on a terminal window to set its transparency as specified (${TRANSPARENCY_PERCENT}%)"
	TERMINAL_WINDOW_XID=$("$XWININFO" | sed -n 's/.*Window id: \([0-9a-fx]\+\).*/\1/p')
else
	# This is very fragile
	# TERMINAL_WINDOW_XID=$("$XWININFO" -root -tree | grep -E -v "Terminal|Gnome-terminal-server" | sed -n 's/^[[:space:]]\+\([0-9a-fx]\+\).*gnome-terminal.*/\1/p')
	# Bug fix remove child windows so that browser title contain terminal won't affected. - Albert Xu <albertxu AT FreeLAMP.com>
	TERMINAL_WINDOW_XID=$("$XWININFO" -root -tree | grep -E -v "Terminal|Gnome-terminal-server" | sed -n 's/^[[:space:]]\{5\}\([0-9a-fx]\+\).*gnome-terminal.*/\1/p')
fi

if [[ $TRANSPARENCY_PERCENT = 100 ]]; then
	TRANSPARENCY_HEX="$OPACITY_100"
elif [[ $TRANSPARENCY_PERCENT = 0 ]]; then
	TRANSPARENCY_HEX="$OPACITY_0"
else
	TRANSPARENCY_HEX=$(printf "0x%x" $((($(printf "%d" $OPACITY_100) * $TRANSPARENCY_PERCENT) / 100)))
fi

echo "Setting transparency to $TRANSPARENCY_HEX (${TRANSPARENCY_PERCENT}%)"
for each in $TERMINAL_WINDOW_XID; do
	"$XPROP" -id $each -f _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY $TRANSPARENCY_HEX
done
