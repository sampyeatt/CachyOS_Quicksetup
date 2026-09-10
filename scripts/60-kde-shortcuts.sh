#!/usr/bin/env bash
# Re-register KDE global shortcuts that point at scripts in ~/.bin.
#
# The launcher .desktop files come from dotfiles/, but the key binding itself
# lives in kglobalshortcutsrc alongside every other KDE shortcut, so it can't
# just be symlinked -- that would clobber the rest. Set only our own keys.
set -euo pipefail
source "$SETUP_ROOT/lib/common.sh"

if ! have kwriteconfig6; then
    warn "kwriteconfig6 not found -- skipping shortcut registration"
    exit 0
fi

# bind DESKTOP_ID KEY
bind_shortcut() {
    local id=$1 key=$2 current

    current=$(kreadconfig6 --file kglobalshortcutsrc \
        --group services --group "$id" --key _launch 2>/dev/null || true)

    if [[ $current == "$key" ]]; then
        skip "$id -> $key"
        return
    fi

    run kwriteconfig6 --file kglobalshortcutsrc \
        --group services --group "$id" --key _launch "$key"
    ok "$id -> $key"
}

bind_shortcut net.local.switchAudio.sh.desktop "Launch (5)"

info "log out and back in for KDE to pick up new shortcuts"
