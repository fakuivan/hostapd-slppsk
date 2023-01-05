#!/usr/bin/env ash
# shellcheck shell=dash
set -euo pipefail

LIB_DIR="$(dirname "$0")"

WIFI_IFACE="$1"
PPSKS_SOURCE_FILE="$2"

# shellcheck source=./manage_common.sh
. "$LIB_DIR/manage_common.sh"

file_resolve () {
    local file_path="$1" dir file
    dir="$(dirname "$file_path")"
    file="$(basename "$file_path")"
    printf "%s" "$(path_resolve "$dir")/$file"
}

# shellcheck source=./iface_common.sh
. "$LIB_DIR/iface_common.sh"

# We expect the iface directory to exists
# and the lock to be engaged
ln -s "$(path_resolve "$LIB_DIR")" "$SCRIPT_DIR"

mkdir "$PPSKS_DIR"
ln -s "$PPSKS_SOURCE_FILE" "$PPSKS_FILE"
printf "%s" "" > "$PPSKS_FILE"

if [ $# -gt 2 ]; then
    PERM_MACS_SOURCE_FILE="$(file_resolve "$3")"
    ln -s "$PERM_MACS_SOURCE_FILE" "$PERM_MACS_FILE"
else
    touch "$PERM_MACS_FILE"
fi

