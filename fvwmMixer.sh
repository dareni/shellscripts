#!/bin/bash

vol=`amixer get Master |tail -1 |awk '{print $4}'`
if [[ "${1}" = "up" ]]; then
    vol=$((vol+6500))
    if [[ $vol -gt 65536 ]]; then
        vol=65535
    fi 
else
    vol=$((vol-6500))
    if [[ ( $vol -lt 0 ) || ( "${1}" = "mute" ) ]]; then
        vol=0
    fi 
fi;
amixer set Master $vol  > /dev/null


