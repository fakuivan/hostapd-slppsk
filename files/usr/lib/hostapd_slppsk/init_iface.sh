#!/usr/bin/busybox ash
# shellcheck shell=dash
set -euo pipefail

LIB_DIR="$(dirname "$0")"

WIFI_IFACE="$1"

# shellcheck source=./manage_common.sh
. "$LIB_DIR/manage_common.sh"

file_resolve () {
    local file_path="$1" dir file
    dir="$(dirname "$file_path")"
    file="$(basename "$file_path")"
    printf "%s" "$(path_resolve "$dir")/$file"
}

PERM_MACS_SOURCE_FILE="$(file_resolve "$2")"

# shellcheck source=./iface_common.sh
. "$LIB_DIR/iface_common.sh"

# We expect the iface directory to exists
# and the lock to be engaged
ln -s "$(path_resolve "$LIB_DIR")" "$SCRIPT_DIR"

mkdir "$PPSKS_DIR"
touch "$PPSKS_FILE"

ln -s "$PERM_MACS_SOURCE_FILE" "$PERM_MACS_FILE"
