#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

xhost +si:localuser:root
. ~/bin/shellscripts/config/mouse.env >/tmp/xinitrc.log
xsetroot -xcf ~/bin/shellscripts/resource/crosshair.xcursor 32

SYNCLIENT=`which synclient`
if [ -n "$SYNCLIENT" ]; then
  synclient TapButton1=1
  synclient TapButton2=2
  synclient TapButton3=3
fi


PACMD=`which pacmd`
if [ -n "$PACMD" ]; then
  (
    PA=1
    IT=0
    (while [ $PA -ne 0 ]; do
      sleep 5
      IT=$((IT + 1))
      if [ $IT -eq 3 ]; then
        systemctl --user restart pulseaudio.service
      fi
      pulseaudio --check
      PA=$?
      if [ $PA -eq 0 ]; then
        COUNT=`pacmd list-sinks|grep -c "name: <compressor>"`
          if [ $COUNT -eq 0 ]; then
            #limit volume extremities
            pacmd load-module module-ladspa-sink sink_name=compressor plugin=sc4m_1916 label=sc4m control=1,1.5,401,-30,20,5,12
            pacmd set-default-sink compressor
          fi
      fi
      if [ $IT -gt 5 ]; then
        PA=0
      fi
    done) >/dev/null
  )&
fi

status=`pgrep -fl fvwm`
if [ -z "${status}" ]; then
  rm -f /tmp/fvwm${USER}.log
  fvwm2 >> /tmp/fvwm${USER}.log 2>>/tmp/fvwm${USER}.log
else
  echo fvwm already running! $status
fi
