#!/usr/bin/busybox ash
# shellcheck shell=dash
set -euo pipefail

STA_ADDRESS="$3"

SCRIPT_DIR="$(dirname "$0")"

# shellcheck source=./iface_common.sh
. "$SCRIPT_DIR/iface_common.sh"

if grep -q -- "$STA_ADDRESS" "$PERM_MACS_FILE"; then
    log debug "Permanent PPSK already in list for $STA_ADDRESS"
    exit
fi

echo "$STA_ADDRESS" >> "$PERM_MACS_FILE"

add_permanent_ppsk () {
    PERMANENT_ENTRY="$(get_entry)"
    TEMP_ENTRIES="$(grep -vxF "$PERMANENT_ENTRY" "$TEMP_PPSKS_FILE" || true)"
    log info "Adding permanent PPSK entry for $STA_ADDRESS"
    # Remove from temp (maybe unnecesary?)
    echo "$TEMP_ENTRIES" > "$TEMP_PPSKS_FILE"
    echo "$PERMANENT_ENTRY" >> "$PERM_PPSKS_FILE"
}

for_each_ppsk add_permanent_ppsk

update_ppsks
