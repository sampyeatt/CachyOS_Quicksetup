#!/bin/bash
sink1=alsa_output.usb-Focusrite_Scarlett_Solo_USB_Y7A8TBD17CD522-00.pro-output-0
sink2=alsa_output.usb-SteelSeries_Arctis_Nova_Pro_Wireless-00.pro-output-0

sink1EQ=Eris3-5
sink2EQ=NovaPro

sink_current=`pactl get-default-sink`
echo "Current Sink $sink_current"
case $sink_current in
  $sink1)
    pactl set-default-sink $sink2;
    easyeffects -b 1
    easyeffects -l $sink2EQ
    ACTPR=$(easyeffects -s)
    echo "Current Preset $ACTPR"
    ;;
  $sink2)
    pactl set-default-sink $sink1;
    easyeffects -b 1
    easyeffects -l $sink1EQ
    ACTPR=$(easyeffects -s)
    echo "Current Preset $ACTPR"
    ;;
  *) pactl set-default-sink $sink1 ;;
esac
