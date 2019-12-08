#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

# Automate a periodic mouse click on a window.

#sleep 6; xdotool click --repeat 1000 1
WINID=$1 #use xdotool selectwindow
DELAY=$2
X=$3 #use xev -id winid for mouse location. Test with xdotool mousemove.
Y=$4
if [ -z "$WINID$DELAY$X$Y" ]; then
  echo
  echo  Usage:
  echo         click.sh winId millsecDelay x y
  echo
  exit
fi

while [ 0 ]
  do
    PREVWIN=`xdotool getmouselocation`
    PREVX=`echo $PREVWIN|cut -f1 -d " " |cut -f2 -d:`
    PREVY=`echo $PREVWIN|cut -f2 -d " " |cut -f2 -d:`
    PREVWINID=`echo $PREVWIN|cut -f4 -d " " |cut -f2 -d:`
    SLEEP=0
    if [ $DELAY -ne 0 ]; then
      SLEEP=$DELAY.`head /dev/urandom |cksum |cut -f2 -d " "`
    fi
    xdotool mousemove --window $WINID $X $Y click 1
    xdotool windowfocus $PREVWINID mousemove $PREVX $PREVY
    sleep $SLEEP
done
