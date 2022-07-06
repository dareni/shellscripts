#!/usr/bin/env sh

BPM=$1
PERIOD=`echo "scale=3; 60*1000/$BPM" |bc`
echo $PERIOD

LENGTH=200

DELAY=`echo "scale=3; $PERIOD-$LENGTH" |bc`

beep -r 2000 -d $DELAY -l $LENGTH




