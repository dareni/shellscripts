#!/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git

CTRL=`amixer scontrols |awk '{print $4}'|awk -F"[']" '{ print $2}'`
vol=`amixer get $CTRL |tail -1 |awk '{print $4}' | \
  cut -c1 --complement |cut -f1 -d%`
if [ "${1}" = "up" -o "${1}" = "plus" ]; then
    vol=$((vol+5))
    if [ $vol -gt 100 ]; then
        vol=100
    fi 
else
    vol=$((vol-5))
    if [ $vol -lt 0 -o "${1}" = "mute" ]; then
        vol=0
    fi 
fi;
amixer set $CTRL $vol%  > /dev/null


