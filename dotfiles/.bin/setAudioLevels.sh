#!/usr/bin/env bash
# Make the Focusrite the default sink and set its levels.
# Runs at login via ~/.config/autostart/setAudioLevels.sh.desktop.
set -euo pipefail

sink1=alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7A8TBD17CD522-00.pro-output-0

sink_exists() { pactl list short sinks | cut -f2 | grep -qxF "$1"; }

# Autostart fires before USB audio is necessarily enumerated. Without this the
# pactl calls below just print "Failure: No such entity" and the levels never
# get set.
for _ in $(seq 30); do
    sink_exists "$sink1" && break
    sleep 1
done

if ! sink_exists "$sink1"; then
    echo "setAudioLevels: sink never appeared: $sink1" >&2
    exit 1
fi

pactl set-default-sink "$sink1"

# Left exactly as-is on purpose. Two things about these lines are surprising:
#
#   * They are PER-CHANNEL values (aux0 aux1), not "volume plus a scale".
#   * A bare decimal is read as linear amplitude and converted cubically, so
#     .125 lands on exactly 50% and .12 on 49% -- not 12.5% and 12%.
#
# The two-step exists because setting a volume to the value it already holds
# fires no change event, so .12 nudges it first to make the .125 take effect.
pactl set-sink-volume "$sink1" .12 1.0
sleep .01
pactl set-sink-volume "$sink1" .125 1.0
