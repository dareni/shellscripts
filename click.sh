#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git

# Automate a periodic mouse click on a window.

#sleep 6; xdotool click --repeat 1000 1
#To get the window id use xdotool selectwindow
#Use xev -id winid for mouse location. Test with xdotool mousemove.

CMD=$1
DELAY=$2
FILENAME=$3
DUP=$4
COUNT_LIMIT=$5
if [ \( -z "$DELAY" \) -o \( "$CMD" = "IMAGE" -a -z "$FILENAME" \) ];  then
  if [  ! \( "$CMD" = "FARM"  -o  "$CMD" = "SAND" -o "$CMD" = "MESE" -o \
    "$CMD" = "CLICKER" -o "$CMD" = "POINTS" -o "$CMD" = "AL" \) ];  then
    echo
    echo  Usage:
    echo         click.sh MULTI secDelay
    echo            secDelay may be a float for a portion of a second.
    echo         click.sh CLICK secDelay
    echo            secDelay - integer for seconds before each click.
    echo            Note: secDelay is added to a random generated fraction to
    echo                  for the interval between each click.
    echo         click.sh IMAGE secDelay fileName dup count
    echo            secDelay - seconds before each image
    echo            filename - name for new images
    echo            dup - 2/1 images per shot
    echo            count - number of shots
    return
  fi
fi

getWindowCoordinates() {
  # Prompt for a window click.
  # Return
  #         - window id : F_WINID
  #         - mouseclick window relative X coordinate : F_X
  #         - mouseclick window relative Y coordinate : F_Y

  F_WINID=`xdotool selectwindow`
  #echo winid:$F_WINID
  #get root relative mouseclick coordinates
  F_MOUSELOC=`xdotool getMouselocation`
  #echo $F_MOUSELOC
  F_WINCOORD=`xwininfo -id $F_WINID -stats |grep geometry|sed -e 's/^[[:space:]]*-geometry //' #| cut -d+ -f2,3`
  F_ROOT=`xwininfo -root -stats|grep geometry |sed -e 's/^[[:space:]]*//' |cut -d" " -f2|tr 'x+-' '   '`
  F_ROOTW=`echo $F_ROOT|cut -d" " -f1`
  F_ROOTH=`echo $F_ROOT|cut -d" " -f2`

  F_WINSTATS=`xwininfo -id $F_WINID -stats |awk '{ if ($0 ~ /Width/){ width=$2 } \
    if ($0 ~ /Height/){ height=$2 }
    if ($0 ~ /Corners/){ corner=$2 }
    } END{print corner" "width" "height}'`
  #echo winstats:$F_WINSTATS
  #xwininfo -id $F_WINID -stats |grep geometry
  #xwininfo -id $F_WINID -stats |grep geometry|cut -d"+" -f2,3
  F_WINCOORD=`echo $F_WINSTATS |cut -d" " -f1`
  #echo wincoord:$F_WINCOORD
  F_PLUS=`expr match "$F_WINCOORD" '.*+'`
  F_MINUS=`expr match "$F_WINCOORD" '.*-'`
  F_WINCOORD=`echo $F_WINCOORD |tr 'x+-' '   '`
  F_WINXLOC=`echo $F_WINCOORD |cut -d" " -f1`
  F_WINYLOC=`echo $F_WINCOORD |cut -d" " -f2`
  #echo wincoord:\'$F_WINCOORD\' winx:$F_WINXLOC winy:$F_WINYLOC
  F_WWIDTH=`echo $F_WINSTATS|cut -d" " -f2`
  F_WHEIGHT=`echo $F_WINSTATS|cut -d" " -f3`

  if [ $F_PLUS -eq 0 ]; then
    F_WINXLOC=$(($F_ROOTW-$F_WINXLOC-$F_WWIDTH))
    F_WINYLOC=$(($F_ROOTH-$F_WINYLOC-$F_WHEIGHT))
  elif [ $F_MINUS -eq 0 ]; then
    :
  else
    #-+ or +-
    if [ $F_MINUS -gt $F_PLUS ]; then
      F_WINYLOC=$(($F_ROOTH-$F_WINYLOC-$F_WHEIGHT))
    else
      F_WINXLOC=$(($F_ROOTW-$F_WINXLOC-$F_WWIDTH))
    fi
  fi

  F_MOUSEX=`echo $F_MOUSELOC|cut -d" " -f1|cut -d: -f2`
  F_MOUSEY=`echo $F_MOUSELOC|cut -d" " -f2|cut -d: -f2`
  #echo  winx:$F_WINXLOC winy:$F_WINYLOC mox:$F_MOUSEX moy:$F_MOUSEY
  #Calculate the window relative mouse coordinates.
  F_X=$(($F_MOUSEX-$F_WINXLOC))
  F_Y=$(($F_MOUSEY-$F_WINYLOC))
  #echo $F_WINXLOC $F_WINYLOC $F_MOUSEX $F_MOUSEY $X $Y
}

getch() {
        pid_parent=`ps -h -q "$$" -o ppid `
        key_binder=`ps -h -q $pid_parent -o cmd |grep -c key_binder`
        if [ 1 = "$key_binder" ]; then
          #do not read for a char when triggered from keybinder
          return
        fi
        #read a single char from stdin
        old=$(stty -g)
        #time 1 = 100ms timeout
        stty raw min 0 time 1
        printf '%s' $(dd bs=1 count=1 2>/dev/null)
        stty $old
}

getCommand() {
  XEV_WINID=$1
    xev -id $XEV_WINID -event keyboard | awk ' \
  BEGIN{CTRL=0;PRESS=0;COMMAND=""}
  { if ($0 ~ /KeyPress/) {PRESS=1}
    if ($0 ~ /keycode 37/ && PRESS == 1) {CTRL=1} #Left ALT
    if ($0 ~ /KeyRelease/) {PRESS=0; CTRL=0; COMMAND=""}
    if ($0 ~ /keycode 59/) {COMMAND="START"} #Comma
    if ($0 ~ /keycode 60/) {COMMAND="STOP"} #Fullstop
    if ($0 ~ /keycode 61/) {COMMAND="QUIT"} #Forward Slash
    if (CTRL==1 && length(COMMAND) > 0) {
      print COMMAND
      CTRL=0
      PRESS=0
      COMMAND=""
      fflush()
    }
  }'
}

getRandomDelay() {
  GRD_DELAY=$1
  if [ 0 -ne "$GRD_DELAY" ]; then
    GRD_DELAY=$GRD_DELAY.`head /dev/urandom |cksum |cut -f1 -d " " |cut -c5-8`
  else
    GRD_DELAY=0
  fi
}

getRandom5() {
 a=`head -1 /dev/urandom |cut -b1`
 a=`printf "%03d" "'$a" |cut -b3`
 echo "(5-$a)/2" |bc
}

#Generate a random number between 5 and -4.
getRandom10() {
 a=`head -1 /dev/urandom |cut -b1`
 a=`printf "%03d" "'$a" |cut -b3`
 echo $((5-$a))
}

#Generate a random number between 0 and 63
getRandom50() {
 a=`head -1 /dev/urandom |cut -b1`
 a=`printf "%03i" "'$a" |cut -b1-3`
 echo $a/4 |bc
}

doMouseClick() {
  DMC_WINID=$1
  DMC_X=$2
  DMC_Y=$3
  PREVWIN=`xdotool getmouselocation`
  PREVX=`echo $PREVWIN|cut -f1 -d " " |cut -f2 -d:`
  PREVY=`echo $PREVWIN|cut -f2 -d " " |cut -f2 -d:`
  PREVWINID=`echo $PREVWIN|cut -f4 -d " " |cut -f2 -d:`
  xdotool mousemove --window $DMC_WINID $DMC_X $DMC_Y click 1
  xdotool windowfocus $PREVWINID mousemove $PREVX $PREVY
}

doSimpleClick() {
  DMC_WINID=$1
  DMC_X=$2
  DMC_Y=$3
  xdotool mousemove --window $DMC_WINID $DMC_X $DMC_Y click 1
}

doMouseDClick() {
  DMC_WINID=$1
  DMC_X=$2
  DMC_Y=$3
  REPEAT=1
  if [ -n "$4" ]; then
    REPEAT=$4
  fi
  PREVWIN=`xdotool getmouselocation`
  PREVX=`echo $PREVWIN|cut -f1 -d " " |cut -f2 -d:`
  PREVY=`echo $PREVWIN|cut -f2 -d " " |cut -f2 -d:`
  PREVWINID=`echo $PREVWIN|cut -f4 -d " " |cut -f2 -d:`
  xdotool mousemove --window $DMC_WINID $DMC_X $DMC_Y click --repeat $REPEAT 1
  xdotool windowfocus $PREVWINID mousemove $PREVX $PREVY
}


if [ "$CMD" = "CLICK" ]; then
  echo Click on the window ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo Press {q} to quit ...

  while [ -z `getch` ];
    do
      doMouseClick $WINID $X $Y
      getRandomDelay $DELAY
      SLEEP=$GRD_DELAY
      sleep $SLEEP
  done
elif [ "$CMD" = "MULTI" ]; then
  echo Click on the window ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo Press 'q' to quit ...

  while [ -z `getch` ];
    do
      doMouseClick $WINID $X $Y
      sleep $DELAY
  done
elif [ "$CMD" = "IMAGE" ]; then
  if [ -z "$COUNT_LIMIT" ]; then
    COUNT_LIMIT=0
  fi
  if [ -z "$DUP" ]; then
    DUP=1
  fi

  mkdir "$FILENAME"
  COUNTER=$FILENAME/count
  touch $COUNTER
  COUNT=`cat $COUNTER`
  COUNT=$(($COUNT+1))

  echo Click the top left corner of the image ...
  F_WINID=`xdotool selectwindow`
  F_MOUSELOC=`xdotool getMouselocation`
  TOP_LEFT_X=`echo $F_MOUSELOC|cut -d" " -f1|cut -d: -f2`
  TOP_LEFT_Y=`echo $F_MOUSELOC|cut -d" " -f2|cut -d: -f2`

  echo Click the bottom right corner of the image ...
  F_WINID=`xdotool selectwindow`
  F_MOUSELOC=`xdotool getMouselocation`
  BOTTOM_RIGHT_X=`echo $F_MOUSELOC|cut -d" " -f1|cut -d: -f2`
  BOTTOM_RIGHT_Y=`echo $F_MOUSELOC|cut -d" " -f2|cut -d: -f2`
  WIDTH=$(($BOTTOM_RIGHT_X-$TOP_LEFT_X))
  HEIGHT=$(($BOTTOM_RIGHT_Y-$TOP_LEFT_Y))

  if [ "$DUP" = 2 ]; then
    echo Click the top left corner of the second image ...
    F_WINID=`xdotool selectwindow`
    F_MOUSELOC=`xdotool getMouselocation`
    TOP_LEFT_X2=`echo $F_MOUSELOC|cut -d" " -f1|cut -d: -f2`
    TOP_LEFT_Y2=`echo $F_MOUSELOC|cut -d" " -f2|cut -d: -f2`

    echo Click the bottom right corner of the second image ...
    F_WINID=`xdotool selectwindow`
    F_MOUSELOC=`xdotool getMouselocation`
    BOTTOM_RIGHT_X2=`echo $F_MOUSELOC|cut -d" " -f1|cut -d: -f2`
    BOTTOM_RIGHT_Y2=`echo $F_MOUSELOC|cut -d" " -f2|cut -d: -f2`
    WIDTH2=$(($BOTTOM_RIGHT_X-$TOP_LEFT_X))
    HEIGHT2=$(($BOTTOM_RIGHT_Y-$TOP_LEFT_Y))
  fi

  import -window root -quality 100 -crop ${WIDTH}x${HEIGHT}+${TOP_LEFT_X}+${TOP_LEFT_Y} $FILENAME/$COUNT.jpg
  echo $COUNT > $COUNTER
  echo -n "$COUNT "
  if [ "$DUP" = 2 ]; then
    COUNT=$(($COUNT+1))
    import -window root -quality 100 -crop ${WIDTH}x${HEIGHT}+${TOP_LEFT_X2}+${TOP_LEFT_Y2} $FILENAME/$COUNT.jpg
    echo $COUNT > $COUNTER
    echo -n "$COUNT "
  fi

  echo Click the next button ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y

      echo pc: $COUNT $COUNT_LIMIT
  while [ -z `getch` ] && [ $COUNT -lt "$COUNT_LIMIT" ];
    do
      COUNT=$(($COUNT+1))
      doMouseClick $WINID $X $Y
      getRandomDelay $DELAY
      SLEEP=$GRD_DELAY
      sleep $SLEEP
      import -window root -quality 100 -crop ${WIDTH}x${HEIGHT}+${TOP_LEFT_X}+${TOP_LEFT_Y} $FILENAME/$COUNT.jpg
      echo $COUNT > $COUNTER
      echo -n "$COUNT "
      if [ "$DUP" = 2 ]; then
        COUNT=$(($COUNT+1))
        import -window root -quality 100 -crop ${WIDTH2}x${HEIGHT2}+${TOP_LEFT_X2}+${TOP_LEFT_Y2} $FILENAME/$COUNT.jpg
        echo $COUNT > $COUNTER
        echo -n "$COUNT "
      fi
  done
elif [ "$CMD" = "FARM" ]; then
  echo Click on the window ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo Press 'q' to quit ...

  while [ -z `getch` ];
    do
      doMouseDClick $WINID $X $Y 2
      sleep $DELAY
      xdotool keydown w
      xdotool keyup w
  done
elif [ "$CMD" = "SAND" ]; then
  echo Click on the window ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo Press 'q' to quit ...

  while [ -z `getch` ];
    do
      xdotool mousedown 1
      sleep 2.5
      xdotool mouseup 1
      sleep 1
      xdotool click 3
      sleep 1
  done
elif [ "$CMD" = "MESE" ]; then
  echo Click point 1  ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo Press 'q' to quit ...

  while [ -z `getch` ];
    do
      #Eat mushroom
      xdotool key 1
      xdotool click 1
      xdotool mousedown 1
      sleep .5
      xdotool mouseup 1

      #Place coral
      xdotool key 2
      sleep .5
      xdotool click 3

      #Mine coral with bronze pick
      xdotool key 3
      sleep .5
      xdotool mousedown 1
      sleep .75
      xdotool mouseup 1
  done
elif [ "$CMD" = "AL" ]; then
  read -p "Add delay(sec)?" DELAY
  echo Click point c  ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  doSimpleClick $WINID $X $Y
  while [ -z `getch` ];
  do
    sleep .5
    CWIN=`xdotool getwindowfocus`
    if [ $CWIN -ne $WINID ]; then
      return
    fi
    sleep .5
    CWIN=`xdotool getwindowfocus`
    if [ $CWIN -ne $WINID ]; then
      return
    fi
    x_adj=$(($X+`getRandom5`))
    y_adj=$(($Y+`getRandom5`))
    doSimpleClick $WINID $x_adj $y_adj
    sleep $((DELAY+`getRandom50`))
  done
  return
elif [ "$CMD" = "POINTS" ]; then
  echo start
  . array.env
  read -p "Number of points? " POINT_COUNT

  for c in `jot - 1 ${POINT_COUNT:=1} 1`
  do
    echo Click point $c  ...
    getWindowCoordinates
    set_avar winid $c $F_WINID
    set_avar x $c $F_X
    set_avar y $c $F_Y
    doMouseClick `get_avar winid $c` `get_avar x $c` `get_avar y $c`
    read -p "Add delay?" DELAY
    set_avar delay $c ${DELAY:=0}
    echo `get_avar x $c` `get_avar y $c` `get_avar delay $c`
  done;
  echo Press 'q' to quit ...
  while [ -z `getch` ];
  do
    for c in `jot - 1 ${POINT_COUNT:=1} 1`
    do
      doMouseClick `get_avar winid $c` `get_avar x $c` `get_avar y $c`
      sleep `get_avar delay $c`
    done
  done
  return

elif [ "$CMD" = "CLICKER" ]; then
  echo Click on the window ...
  getWindowCoordinates
  WINID=$F_WINID
  X=$F_X
  Y=$F_Y
  echo ctrl-,  start
  echo ctrl-.  stop
  echo ctrl-/  quit
  CMD=""
 xev -id $WINID
exit
  getCommand $WINID | \
  while read KEY; do
    if [ "$KEY" == "START" ]; then
      echo "START"
      CMD=$KEY
    elif [ "$KEY" == "STOP" ]; then
      echo "STOP"
      CMD=$KEY
    elif [ "$KEY" == "QUIT" ]; then
      echo "QUIT"
      kill -15 `ps |grep "xev" | cut -d" " -f 1`
      exit;
    fi
    if [ "$CMD" == "START" ]; then
      doMouseClick $WINID $X $Y
    fi
  done;
fi
