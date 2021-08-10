# Maintained at: git@github.com:dareni/shellscripts.git
~/bin/shellscripts/fvwminit.sh

xhost +si:localuser:root
. ~/bin/shellscripts/config/mouse.env >/tmp/xinitrc.log
xsetroot -xcf ~/bin/shellscripts/resource/crosshair.xcursor 32

(
  PA=1
  (while [ $PA -ne 0 ]; do
    sleep 20
    pulseaudio --check
    PA=$?
    if [ $PA -ne 0 ]; then
      pulseaudio -D
      COUNT=`pacmd list-sinks|grep -c "name: <compressor>"`
        if [ $COUNT -eq 0 ]; then
          #limit volume extremities
          pacmd load-module module-ladspa-sink sink_name=compressor plugin=sc4m_1916 label=sc4m control=1,1.5,401,-30,20,5,12
          pacmd set-default-sink compressor
        fi
    fi
  done) >/dev/null
)&

status=`pgrep -fl fvwm`
if [ -z "${status}" ]; then
  rm -f /tmp/fvwm${USER}.log
  fvwm2 >> /tmp/fvwm${USER}.log 2>>/tmp/fvwm${USER}.log
else
  echo fvwm already running! $status
fi
