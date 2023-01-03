#!/usr/bin/busybox ash
# shellcheck shell=dash

PROGRAM_DIR=/home/fakui/whome/Seafile/Programming/projects/wpa_ppsk/tests/var/run/hostapd_slppsk
#/var/run/hostapd_slppsk
IFACE_CONFIG="$PROGRAM_DIR/$WIFI_IFACE"
# shellcheck disable=SC2034
SCRIPT_DIR="$IFACE_CONFIG/scripts"

path_resolve () {
    local path="$1"
    (cd "$path" && pwd)
}
