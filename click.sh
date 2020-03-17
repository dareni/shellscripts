#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

# Automate a periodic mouse click on a window.

#sleep 6; xdotool click --repeat 1000 1
#To get the window id use xdotool selectwindow
#Use xev -id winid for mouse location. Test with xdotool mousemove.

DELAY=$1
if [ -z "$DELAY" ]; then
  echo
  echo  Usage:
  echo         click.sh millsecDelay
  echo   For winid use xdotool selectwindow
  exit
fi

echo Click on the window ...
WINID=`xdotool selectwindow`
#echo winid:$WINID
MOUSELOC=`xdotool getMouselocation`
WINCOORD=`xwininfo -id $WINID -stats |grep geometry|sed -e 's/^[[:space:]]*-geometry //' #| cut -d+ -f2,3`
ROOT=`xwininfo -root -stats|grep geometry |sed -e 's/^[[:space:]]*//' |cut -d" " -f2|tr 'x+-' '   '`
ROOTW=`echo $ROOT|cut -d" " -f1`
ROOTH=`echo $ROOT|cut -d" " -f2`

WINSTATS=`xwininfo -id $WINID -stats |awk '{ if ($0 ~ /Width/){ width=$2 } \
  if ($0 ~ /Height/){ height=$2 }
  if ($0 ~ /geometry/){ geometry=$2 }
  } END{print geometry" "width" "height}'` 
#xwininfo -id $WINID -stats |grep geometry
#xwininfo -id $WINID -stats |grep geometry|cut -d"+" -f2,3
WINCOORD=`echo $WINSTATS |cut -d" " -f1`
#echo $WINCOORD
PLUS=`expr match "$WINCOORD" '.*+'`
MINUS=`expr match "$WINCOORD" '.*-'`
WINCOORD=`echo $WINCOORD |tr 'x+-' '   '`
WINXLOC=`echo $WINCOORD |cut -d" " -f3`
WINYLOC=`echo $WINCOORD |cut -d" " -f4`
WWIDTH=`echo $WINSTATS|cut -d" " -f2`
WHEIGHT=`echo $WINSTATS|cut -d" " -f3`

if [ $PLUS -eq 0 ]; then
  WINXLOC=$(($ROOTW-$WINXLOC-$WWIDTH))
  WINYLOC=$(($ROOTH-$WINYLOC-$WHEIGHT))
elif [ $MINUS -eq 0 ]; then
  : 
else
  #-+ or +-
  if [ $MINUS -gt $PLUS ]; then
    WINYLOC=$(($ROOTH-$WINYLOC-$WHEIGHT))
  else
    WINXLOC=$(($ROOTW-$WINXLOC-$WWIDTH))
  fi
fi

MOUSEX=`echo $MOUSELOC|cut -d" " -f1|cut -d: -f2`
MOUSEY=`echo $MOUSELOC|cut -d" " -f2|cut -d: -f2`
#echo  $WINXLOC $WINYLOC $MOUSEX $MOUSEY
#Calculate the window relative mouse coordinates.
X=$(($MOUSEX-$WINXLOC))
Y=$(($MOUSEY-$WINYLOC))
#echo $WINXLOC $WINYLOC $MOUSEX $MOUSEY $X $Y

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
