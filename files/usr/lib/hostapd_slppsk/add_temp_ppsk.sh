#!/usr/bin/busybox ash
# shellcheck shell=dash
set -euo pipefail

STA_ADDRESS="$3"

SCRIPT_DIR="$(dirname "$0")"

# shellcheck source=./iface_common.sh
. "$SCRIPT_DIR/iface_common.sh"

if grep -q -- "$STA_ADDRESS" "$PERM_MACS_FILE"; then
    log debug "Temp PPSK already in permanent list for $STA_ADDRESS"
    exit
fi

add_temp_ppsk () {
    local temp_entries
    if grep -q -- "$STA_ADDRESS" "$TEMP_PPSKS_FILE"; then
        log debug "Temp PPSK already in temp list for $STA_ADDRESS of $key_id"
        return
    fi
    touch "$OUT_OF_SYNC_FILE"
    temp_entries="$(
        head -n "$(($MAX_TEMP_ENTRIES - 1))" -- "$TEMP_PPSKS_FILE"
    )"
    log info "Adding temp PPSK for $STA_ADDRESS to $key_id"
    get_entry > "$TEMP_PPSKS_FILE"
    echo "$temp_entries" >> "$TEMP_PPSKS_FILE"
}

for_each_ppsk add_temp_ppsk

if [ -e "$OUT_OF_SYNC_FILE" ]; then
    update_ppsks
    rm "$OUT_OF_SYNC_FILE"
fi
