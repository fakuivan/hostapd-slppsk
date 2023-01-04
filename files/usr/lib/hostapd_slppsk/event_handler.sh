#!/usr/bin/env ash
# shellcheck shell=dash
set -euo pipefail

EVENT="$2"

SCRIPT_DIR="$(dirname "$0")"

# shellcheck source=./iface_common.sh
. "$SCRIPT_DIR/iface_common.sh"

case "$EVENT" in
    "AP-STA-POSSIBLE-PSK-MISMATCH")
        flock "$LOCK_FILE" "$SCRIPT_DIR"/add_temp_ppsk.sh "$@"
        ;;

    #"EAPOL-4WAY-HS-COMPLETED")
    "AP-STA-CONNECTED")
        flock "$LOCK_FILE" "$SCRIPT_DIR"/add_permanent_ppsk.sh "$@"
        ;;
esac
