#!/usr/bin/env sh
#
SH_PID=$$
FVWM_PID=`ps -ho ppid $SH_PID`
#echo `ps -h $FVWM_PID` > /tmp/fvwmpid
XINIT_PID=`ps -ho ppid $FVWM_PID`
kill -15 $XINIT_PID
