#!/usr/bin/env bash
set -euo pipefail

first_valid_command () {
    while (($# > 0)); do
        if command -v "$1" &> /dev/null; then
            printf "%s" "$1"
            return 0
        fi
        shift
    done
    return 1
}

if ! ENGINE="$(first_valid_command podman docker)"; then
    echo "Failed to find 'podman' or 'docker' command" 1>&2
    exit 1
fi

BIN_DIR="$1"
# These shouldn't matter much since we're building a script only package
SDK_TAG="${2:-"mips_24kc-22.03.3"}"
SDK_REPO="${3:-"docker.io/openwrtorg/sdk"}"

build () {
    local temp_dir="$1"
    "$ENGINE" run --rm -u root \
        -v .:/home/build/openwrt/package/slppsk-hostapd \
        -v "$temp_dir":/home/build/openwrt/bin/ \
        -ti "$SDK_REPO":"$SDK_TAG" \
        bash -c 'make defconfig
                 make package/slppsk-hostapd/compile -j$(nproc)'
    cp "$temp_dir"/packages/*/base/slppsk-hostapd_*_all.ipk "$BIN_DIR"
}

with_temp_dir () {
    local temp_dir ret=0 cmd="$1"
    shift
    temp_dir="$(mktemp -d)"
    "$cmd" "$temp_dir" "$@" || ret=$?
    rm -rf "$temp_dir"
    return $ret
}

with_temp_dir build
