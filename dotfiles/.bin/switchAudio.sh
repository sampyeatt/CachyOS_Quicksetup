#!/usr/bin/env bash
# Toggle the default sink between the Focusrite and the SteelSeries, loading
# the matching EasyEffects preset. Bound to Launch (5) via
# ~/.local/share/applications/net.local.switchAudio.sh.desktop.
set -euo pipefail

sink1=alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7A8TBD17CD522-00.pro-output-0
sink2=alsa_output.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.pro-output-0

sink1EQ=Eris3-5
sink2EQ=NovaPro

sink_exists() { pactl list short sinks | cut -f2 | grep -qxF "$1"; }
sink_index()  { pactl list short sinks | awk -v n="$1" '$2 == n { print $1 }'; }

# Streams reach the hardware through easyeffects_sink, so they must NOT be
# moved -- doing that would pull them out of the processing chain and silently
# bypass every effect. Only relocate streams bound straight to the old device.
move_direct_streams() {
    local from=$1 to=$2 from_idx id sink_idx

    from_idx=$(sink_index "$from")
    [[ -n $from_idx ]] || return 0

    while read -r id sink_idx _; do
        [[ $sink_idx == "$from_idx" ]] || continue
        pactl move-sink-input "$id" "$to" 2>/dev/null || true
    done < <(pactl list short sink-inputs)
}

switch_to() {
    local from=$1 to=$2 preset=$3

    if ! sink_exists "$to"; then
        echo "switchAudio: sink not available: $to" >&2
        exit 1
    fi

    pactl set-default-sink "$to"
    move_direct_streams "$from" "$to"

    if command -v easyeffects >/dev/null; then
        easyeffects -l "$preset"
        # 2 DISABLES global bypass. Passing 1 enables it, which loads the
        # preset and then turns all processing off.
        easyeffects -b 2
        echo "Current preset $(easyeffects -s)"
    fi

    echo "Switched to $to"
}

current=$(pactl get-default-sink)
echo "Current sink $current"

# Patterns are quoted so they match literally rather than as globs.
case $current in
    "$sink1") switch_to "$sink1" "$sink2" "$sink2EQ" ;;
    "$sink2") switch_to "$sink2" "$sink1" "$sink1EQ" ;;
    *)        switch_to "$current" "$sink1" "$sink1EQ" ;;
esac
