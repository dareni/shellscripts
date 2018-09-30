#!/usr/local/bin/bash

TEST=$1

function getStats() {
  upower -d |egrep 'on-battery|percentage'
}

function showMessage() {
  (xterm -geometry 100x6-0+0 -fa *courier* -fs 12 -bg darkgray -fg black -e ~/bin/shellscripts/timer.sh 0 "$1")&
}


function getMessage() {
  PERCENT=$1
  ONBAT=$2
  OLD_PERCENT=$3
  MSG=""
  if [[ ! $PERCENT =~ ^-?[0-9]+$ ]]; then
    MSG="Error calculating battery capacity."
  elif [[ "$ONBAT" = yes ]]; then
   if [[ -z "$OLD_PERCENT" ]]; then
     if [[ $PERCENT -eq 100 ]]; then
       MSG="On battery 100% capacity."
        OLD_PERCENT=90
     else
       MSG="On battery $PERCENT capacity."
       OLD_PERCENT=$(($PERCENT / 10 * 10))
     fi;
    elif [[ $PERCENT -lt $OLD_PERCENT ]]; then
       OLD_PERCENT=$((${PERCENT} / 10 * 10))
       MSG="On battery. Down to $PERCENT% capacity."
    fi
  else
    OLD_PERCENT=""
  fi
  MSG="$MSG,$OLD_PERCENT"
  echo $MSG
}

function decodeMessage() {
  MSG=$1
  TXT=`echo "$MSG" | cut -d, -f 1`
  echo $TXT
}

function decodePercent() {
  MSG=$1
  OLD_PERCENT=`echo "$MSG" | cut -d, -f 2-`
  echo $OLD_PERCENT
}

function testIt() {
  RET=`decodeMessage "1 2, 3"`
  assert "decodeMessage test" "1 2" "$RET"

  RET=`decodePercent "1 2, 3"`
  assert "decodePercent test" "3" "$RET"

  RET=`getMessage 100 yes`
  assert "gMess1" "On battery 100% capacity.,90" "$RET"

  RET=`getMessage 100 yes 90`
  assert "gMess2" ",90" "$RET"

  RET=`getMessage 99  yes 90`
  assert "gMess3" ",90" "$RET"

  RET=`getMessage 89 yes 90`
  assert "gMess4" "On battery. Down to 89% capacity.,80" "$RET"

  RET=`getMessage 89 no 90`
  assert "gMess5" "," "$RET"
}

function assert() {
  MSG=$1
  ARG1=$2
  ARG2=$3
  if [[ "$ARG1" != "$ARG2" ]]; then
    echo error: $MSG $ARG1 != $ARG2
    return 1;
  fi
}


if [[ "$TEST" = TEST ]]; then
  testIt
else
  EPID=`pgrep -o funcPower.sh`

  if [[ -n `which upower` ]]; then
    OLD_PERCENT="";
    if [ "$$" -eq "$EPID" ]; then
      (while [ 1 ]; do
        STAT=`getStats`
        PERCENT=`echo $STAT | awk '{print $4}'| awk -F% '{print $1}'`
        ONBAT=`echo $STAT | awk '{print $6}'`
        echo getMessage $PERCENT $ONBAT $OLD_PERCENT
        MSG=`getMessage $PERCENT $ONBAT $OLD_PERCENT`
        echo $MSG
        OLD_PERCENT=`decodePercent "$MSG"`
        TXT=`decodeMessage "$MSG"`
        if [[ -n $TXT ]]; then
          showMessage "$TXT"
        fi
        sleep 60
      done)&
    fi
  fi
fi

