#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

#xdg-settings set default-web-browser luakit.desktop

xhost +si:localuser:root
. ~/bin/shellscripts/config/mouse.env >/tmp/xinitrc.log
xsetroot -xcf ~/bin/shellscripts/resource/crosshair.xcursor 32

SYNCLIENT=`which synclient`
if [ -n "$SYNCLIENT" ]; then
  synclient TapButton1=1
  synclient TapButton2=2
  synclient TapButton3=3
  synclient PalmDetect=1
fi


#install swh-plugins - Steve Harris's LADSPA plugins

pactl load-module module-ladspa-sink sink_name=compressor \
       plugin=sc4m_1916 label=sc4m control=1,1.5,401,-30,20,5,12
pactl set-default-sink compressor


status=`pgrep -fl fvwm`
if [ -z "${status}" ]; then
  rm -f /tmp/fvwm${USER}.log
  fvwm2 >> /tmp/fvwm${USER}.log 2>>/tmp/fvwm${USER}.log
else
  echo fvwm already running! $status
fi
