#!/usr/bin/env bash
# Make pacman pleasant, then sync the system.
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

conf=/etc/pacman.conf

# Uncomment/add a setting in the [options] block if it isn't already active.
enable_opt() {
    local key=$1
    if grep -qE "^[[:space:]]*${key}\b" "$conf"; then
        skip "$key already set"
    elif grep -qE "^[[:space:]]*#[[:space:]]*${key}\b" "$conf"; then
        run sudo sed -i -E "s/^[[:space:]]*#[[:space:]]*(${key}\b.*)/\1/" "$conf"
        ok "enabled $key"
    else
        run sudo sed -i "/^\[options\]/a ${key}" "$conf"
        ok "added $key"
    fi
}

enable_opt Color
enable_opt VerbosePkgLists
enable_opt "ParallelDownloads = 10"

if ! grep -qE '^[[:space:]]*ILoveCandy' "$conf"; then
    run sudo sed -i '/^\[options\]/a ILoveCandy' "$conf"
    ok "added ILoveCandy"
else
    skip "ILoveCandy already set"
fi

info "syncing system"
run sudo pacman -Syu --noconfirm
