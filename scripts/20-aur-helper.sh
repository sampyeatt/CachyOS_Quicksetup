#!/usr/bin/env bash
# Ensure an AUR helper exists. Bootstraps paru from source if not.
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

if helper=$(aur_helper); then
    skip "$helper already installed"
    exit 0
fi

info "bootstrapping paru"
run sudo pacman -S --needed --noconfirm base-devel git

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT
run git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$build/paru-bin"
if [[ $DRY_RUN == 0 ]]; then
    ( cd "$build/paru-bin" && makepkg -si --noconfirm )
fi
ok "paru installed"
