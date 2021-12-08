#!/usr/bin/env sh
# Maintained at: git@github.com:dareni/shellscripts.git
PAD=`synclient |grep TouchpadOff |awk '{print $3}'`
if [ $PAD -eq 0 ]; then
  synclient TouchpadOff=1;
else
  synclient TouchpadOff=0;
fi

