#!/usr/bin/busybox ash
# shellcheck shell=dash

IFACE_CONFIG="${IFACE_CONFIG:-$(dirname "$SCRIPT_DIR")}"
# shellcheck disable=SC2034
{
    PPSKS_DIR="$IFACE_CONFIG/ppsks"
    LOCK_FILE="$IFACE_CONFIG/lock"
    PPSKS_FILE="$IFACE_CONFIG/merged.psk"
    PERM_MACS_FILE="$IFACE_CONFIG/perm_macs.txt"
    PID_FILE="$IFACE_CONFIG/pid"
    OUT_OF_SYNC_FILE="$IFACE_CONFIG/dirty"
}

log () {
    local level="$1"
    shift
    if [ info = "$level" ]; then
        echo "$level:" "$@"
    fi
}

for_each_ppsk () {
    local ppsk_dir key_id
    for ppsk_dir in "$PPSKS_DIR"/*; do
        key_id="$(basename "$ppsk_dir")"
        (. "$SCRIPT_DIR/key_common.sh"; "$@" "$key_id")
    done
}

add_ppsks () {
    local key_id="$1"
    {
        echo "# Entries for master key id $key_id"
        echo "# Permanent PPSKS
"
        cat "$PERM_PPSKS_FILE"
        echo "# Temporary PPSKS (waiting for successful authentication)
"
        cat "$TEMP_PPSKS_FILE"
    } >> "$PPSKS_FILE"
}

hostapd_reload () {
    hostapd_cli \
        -i "$(basename "$IFACE_CONFIG")" \
        reload_wpa_psk
}

update_ppsks () {
    printf "%s" "" > "$PPSKS_FILE"
    for_each_ppsk add_ppsks
    hostapd_reload
}

get_entry () {
    echo "$KEY_PARAMS $STA_ADDRESS $(get_ppsk)"
}

get_ppsk () {
    printf "%s%s" \
            "$MASTER_PSK" \
            "$(echo "$STA_ADDRESS" | tr -d : | xxd -r -p)" | \
        sha256sum | \
        cut -d" " -f 1 | \
        /usr/bin/xxd -r -p | \
        head -c "$PPSK_BYTE_LEN" | \
        base64
}
