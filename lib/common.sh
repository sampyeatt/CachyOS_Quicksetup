#!/usr/bin/env bash
# Shared helpers. Sourced by every stage script.

SETUP_ROOT="${SETUP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"

if [[ -t 1 ]]; then
    C_RESET=$'\e[0m'; C_BLUE=$'\e[34m'; C_GREEN=$'\e[32m'
    C_YELLOW=$'\e[33m'; C_RED=$'\e[31m'; C_DIM=$'\e[2m'
else
    C_RESET=; C_BLUE=; C_GREEN=; C_YELLOW=; C_RED=; C_DIM=
fi

info()  { printf '%s==>%s %s\n' "$C_BLUE"   "$C_RESET" "$*"; }
ok()    { printf '%s  ok%s %s\n' "$C_GREEN"  "$C_RESET" "$*"; }
warn()  { printf '%swarn%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()   { printf '%serr!%s %s\n' "$C_RED"    "$C_RESET" "$*" >&2; exit 1; }
skip()  { printf '%s  -- %s%s\n' "$C_DIM"    "$*" "$C_RESET"; }

# run CMD...  -- executes, or just prints it under --dry-run
run() {
    if [[ $DRY_RUN == 1 ]]; then
        printf '%s  $ %s%s\n' "$C_DIM" "$*" "$C_RESET"
    else
        "$@"
    fi
}

# read_list FILE -- emit one item per line, stripping # comments and blanks
read_list() {
    [[ -f $1 ]] || return 0
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e 's/^[[:space:]]*//' "$1" \
        | grep -v '^$' || true
}

have() { command -v "$1" >/dev/null 2>&1; }

# The AUR helper to use, whichever is present.
aur_helper() {
    for h in paru yay; do have "$h" && { echo "$h"; return; }; done
    return 1
}
