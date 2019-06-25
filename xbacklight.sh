#!/bin/sh

CMD=$1

if [ -x xbacklight ]; then
  if [ -z "$CMD" ]; then
    SETTING=`xbacklight -get `
    SETTING=`printf %.0f $SETTING`

    if [ -z "$SETTING" ]; then
      xbacklight -set 50
      echo 50
    elif [ "$SETTING" -ge 90 ]; then
      xbacklight -set 10
      echo 10
    else
      SETTING=`echo "$SETTING+10" |bc|tail -1`
      xbacklight -set $SETTING
      echo set
    fi
  else
    if [ ${CMD} = "plus" ]; then
        xbacklight -inc 10
        echo plus
    else
        xbacklight -dec 10
        echo dec
    fi
  fi
elif [ -f /sys/class/backlight/rpi_backlight/brightness ]; then
  #Raspberry Pi LCD backlight
  LEVEL=`cat /sys/class/backlight/rpi_backlight/brightness`
  if [ ${CMD} = "plus" ]; then
    if [ $LEVEL -lt 90 ]; then
      LEVEL=$(($LEVEL+5))
    fi
  else
    if [ $LEVEL -gt 15 ]; then
      LEVEL=$(($LEVEL-5))
    fi
  fi
  echo $LEVEL | sudo tee /sys/class/backlight/rpi_backlight/brightness
fi
