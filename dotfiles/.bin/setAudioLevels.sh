#!/bin/bash
sink1=alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7A8TBD17CD522-00.pro-output-0

pactl set-default-sink $sink1
pactl set-sink-volume $sink1 .12 1.0
sleep .01
pactl set-sink-volume $sink1 .125 1.0

