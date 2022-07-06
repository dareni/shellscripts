#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git

#ON or OFF, empty is a toggle.
TOUCH_PAD=$1
if [ -n "`which synclient`" ]; then
  if [ -z "$TOUCH_PAD" ]; then
    PAD=`synclient |grep TouchpadOff |awk '{print $3}'`
  else
    if [ "ON" = "$TOUCH_PAD" ]; then
      PAD=1
    else
      PAD=0
    fi
  fi
  if [ $PAD -eq 0 ]; then
    synclient TouchpadOff=1;
  else
    synclient TouchpadOff=0;
  fi
fi
