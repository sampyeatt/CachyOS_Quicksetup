#!/usr/bin/env bash
# Symlink everything under dotfiles/ into $HOME, mirroring the tree.
#
#   dotfiles/.config/foo/bar.toml  ->  ~/.config/foo/bar.toml
#
# Anything real that's already in the way gets moved to ~/.dotfiles-backup/<stamp>/.
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

src="$SETUP_ROOT/dotfiles"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0

mapfile -t files < <(find "$src" -type f -not -name '.gitkeep' -printf '%P\n' | sort)

if [[ ${#files[@]} -eq 0 ]]; then
    skip "dotfiles/ is empty -- nothing to link"
    exit 0
fi

for rel in "${files[@]}"; do
    target="$HOME/$rel"

    # Already pointing where we want it.
    if [[ -L $target && $(readlink -f "$target") == "$src/$rel" ]]; then
        skip "$rel"
        continue
    fi

    if [[ -e $target || -L $target ]]; then
        run mkdir -p "$backup/$(dirname "$rel")"
        run mv "$target" "$backup/$rel"
        backed_up=1
        warn "backed up existing $rel"
    fi

    run mkdir -p "$(dirname "$target")"
    run ln -s "$src/$rel" "$target"
    ok "$rel"
done

[[ $backed_up == 1 ]] && info "replaced files saved in $backup"
exit 0
