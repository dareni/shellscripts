#!/bin/sh
TIMER=0
CNT=$1
MESSAGE=$2
if [ -z "$CNT" ]; then  
    echo "Enter the count in minutes. eg ./timer.sh 10"
    return;
fi;

if [ -z `which beep` ]; then
    echo "Error: The 'beep' executable not accessible."
    echo "Install beep: apt-get install beep"
    return;
fi;

while [ $TIMER -lt $CNT ]
do 
   sleep 1m;
   TIMER=$(($TIMER+1))
   echo $TIMER
done;

if [ ! -z $MESSAGE ]; then
    echo $MESSAGE
fi
beep -d 1000 -r 3600&
BEEP_PID=$!

read -p "Press enter to close:" dummy

kill -15 $BEEP_PID

