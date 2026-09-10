#!/usr/bin/env bash
# Enable the units listed in services/.
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

# enable_units LIST_FILE [--user]
enable_units() {
    local list=$1; shift
    local sc=(systemctl "$@") unit
    # system units need root, user units must not have it
    local pre=(sudo); [[ ${1:-} == --user ]] && pre=()

    while read -r unit; do
        if "${sc[@]}" is-enabled --quiet "$unit" 2>/dev/null; then
            skip "$unit"
        elif ! "${sc[@]}" list-unit-files "$unit" --no-legend 2>/dev/null | grep -q .; then
            warn "$unit not installed -- skipping"
        else
            run "${pre[@]}" "${sc[@]}" enable --now "$unit"
            ok "$unit"
        fi
    done < <(read_list "$list")
}

info "system units"
enable_units "$SETUP_ROOT/services/system.txt"

info "user units"
enable_units "$SETUP_ROOT/services/user.txt" --user
