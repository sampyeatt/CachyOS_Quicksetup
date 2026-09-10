#!/usr/bin/env bash
# Install everything listed under packages/.
#
#   packages/*.txt           installed from the official repos
#   packages/aur.txt         installed via the AUR helper
#   packages/optional/*.txt  ignored -- move a list here to disable it
#
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

repo_pkgs=()
for list in "$SETUP_ROOT"/packages/*.txt; do
    [[ -e $list ]] || continue
    [[ $(basename "$list") == aur.txt ]] && continue
    mapfile -t -O "${#repo_pkgs[@]}" repo_pkgs < <(read_list "$list")
done

if [[ ${#repo_pkgs[@]} -gt 0 ]]; then
    info "${#repo_pkgs[@]} repo packages"
    # --needed makes this a no-op for anything already present.
    run sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}"
else
    skip "no repo packages listed"
fi

mapfile -t aur_pkgs < <(read_list "$SETUP_ROOT/packages/aur.txt")
if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    helper=$(aur_helper) || die "no AUR helper -- run stage 20 first"
    info "${#aur_pkgs[@]} AUR packages via $helper"
    run "$helper" -S --needed --noconfirm "${aur_pkgs[@]}"
else
    skip "no AUR packages listed"
fi
