#!/usr/bin/env ash
# shellcheck shell=dash
set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"

echoerr() { echo "$@" 1>&2; }

# shellcheck source=./iface_common.sh
. "$SCRIPT_DIR/iface_common.sh"

# Taken from https://github.com/python/cpython/blob/f4fcfdf8c593611f98b9358cc0c5604c15306465/Lib/shlex.py#L321-L332
quote () {
    printf "'"
    # replaces ' with '"'"'
    sed "s/'/'"'"'"'"'"'"'/g"
    printf "'"
}

quote_arg () {
    printf "%s" "$1" | quote
}

params_file () {
    local value
    for arg in "$@"; do
        value="$(eval 'printf "%s" "$'"$arg"'"')"
        printf "%s=%s\n" "$arg" "$(quote_arg "$value")"
    done
}

get_psk_id () {
    local psk="$1"
    printf "%s" "$psk" | \
        sha256sum | \
        cut -d" " -f 1 | \
        head -c12
}

check_mac_addr () {
    local addr="$1"
    # shellcheck disable=SC3010
    if ! printf "%s" "$addr" | grep -qE \
            '^\s*([0-9A-Fa-f]{2}:){5}([0-9A-Fa-f]{2})\s*$'; then
        echoerr "invalid MAC address: '$addr'"
        return 1
    fi
    printf "%s" "$addr" | tr -dc 'a-fA-F0-9:'
}

MIN_PSK_LEN=12
MIN_PPSK_BYTE_LEN=8

if [ -z "${MASTER_PSK+x}" ]; then
    echoerr 'The master PSK must be exported to the MASTER_PSK' \
        'environment variable'
    exit 1
fi
if [ "${#MASTER_PSK}" -lt "$MIN_PSK_LEN" ]; then
    echoerr "The master PSK must be at least $MIN_PSK_LEN" \
        "characters long"
    exit 1
fi

# shellcheck disable=SC2034
MAX_TEMP_ENTRIES="$1"
KEY_PARAMS="$2"
PPSK_BYTE_LEN="$3"

if [ "$MIN_PPSK_BYTE_LEN" -gt "$PPSK_BYTE_LEN" ]; then
    echoerr "The ppsks must be at least $MIN_PPSK_BYTE_LEN" \
        "bytes long"
    exit 1
fi

key_id="$(get_psk_id "$MASTER_PSK")"
# Don't import params file since it hasn't been created yet
IGNORE_PARAMS=true
. "$SCRIPT_DIR"/key_common.sh
unset IGNORE_PARAMS

mkdir "$KEY_CONFIG_DIR"
# Create the params file and add the following vars
params_file \
    MASTER_PSK \
    MAX_TEMP_ENTRIES \
    KEY_PARAMS \
    PPSK_BYTE_LEN > "$PARAMS_FILE"
touch "$PERM_PPSKS_FILE" "$TEMP_PPSKS_FILE"

# "Manually" add the entries to the ppsks file to avoid
# rewriting each time a password is initialized
while read -r STA_ADDRESS; do
    if ! STA_ADDRESS="$(check_mac_addr "$STA_ADDRESS")"; then
        continue
    fi
    get_entry >> "$PERM_PPSKS_FILE"
done < "$PERM_MACS_FILE"

add_ppsks "$key_id"
hostapd_reload
