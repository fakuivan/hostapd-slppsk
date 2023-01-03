#!/usr/bin/busybox ash
# shellcheck shell=dash

# shellcheck disable=SC2154
KEY_CONFIG_DIR="$PPSKS_DIR/$key_id"
# shellcheck disable=SC2034
TEMP_PPSKS_FILE="$KEY_CONFIG_DIR/temp.psk"
# shellcheck disable=SC2034
PERM_PPSKS_FILE="$KEY_CONFIG_DIR/perm.psk"
PARAMS_FILE="$KEY_CONFIG_DIR/params.env"

if [ "${IGNORE_PARAMS:-false}" != "true" ]; then
    # shellcheck source=./params.env
    . "$PARAMS_FILE"
fi
