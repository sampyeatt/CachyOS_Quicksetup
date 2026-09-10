#!/usr/bin/env bash
#
# Entry point. Run all stages, or just the ones you name.
#
#   ./install.sh                 # everything
#   ./install.sh --list          # show stages
#   ./install.sh --dry-run       # print what would happen, change nothing
#   ./install.sh packages        # run only 30-packages.sh
#   ./install.sh 30 50           # run stages 30 and 50
#
set -euo pipefail

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SETUP_ROOT
source "$SETUP_ROOT/lib/common.sh"

export DRY_RUN=0
targets=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=1 ;;
        -l|--list)
            printf 'Stages:\n'
            for s in "$SETUP_ROOT"/scripts/[0-9]*.sh; do
                printf '  %s\n' "$(basename "$s" .sh)"
            done
            exit 0 ;;
        -h|--help) sed -n '2,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
        -*) die "unknown option: $1" ;;
        *) targets+=("$1") ;;
    esac
    shift
done

[[ $EUID -eq 0 ]] && die "run as your normal user, not root (sudo is called where needed)"
[[ -f /etc/arch-release ]] || warn "this doesn't look like an Arch-based system"

# Resolve which stage scripts to run.
stages=()
if [[ ${#targets[@]} -eq 0 ]]; then
    mapfile -t stages < <(ls "$SETUP_ROOT"/scripts/[0-9]*.sh)
else
    for t in "${targets[@]}"; do
        matches=("$SETUP_ROOT"/scripts/*"$t"*.sh)
        [[ -e ${matches[0]} ]] || die "no stage matching '$t' (try --list)"
        stages+=("${matches[@]}")
    done
fi

[[ $DRY_RUN == 1 ]] && warn "dry run -- nothing will be changed"

# Prime sudo once so stages don't each stop to prompt.
if [[ $DRY_RUN == 0 ]]; then
    sudo -v
    while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done 2>/dev/null &
fi

for stage in "${stages[@]}"; do
    info "$(basename "$stage" .sh)"
    bash "$stage"
done

info "done"
