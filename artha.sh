#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
# Toggle the state of artha the thesaurus. Used by fvwm button.

STATE=`xwininfo -name "Artha ~ The Open Thesaurus" |grep "Map State"`;
UNMAPPED=`echo $STATE | grep -c IsUnMapped`;
VIEWABLE=`echo $STATE | grep -c IsViewable`;
if [ "$UNMAPPED" -eq 1 ]; then
  xdotool key ctrl+alt+w
elif [ "$VIEWABLE" -eq 1 ]; then
  xdotool search --name "Artha ~ The Open Thesaurus" key Escape
else
  ARTHA=`pgrep " artha "`
  if [ -z "$ARTHA" ]; then
    artha
  else
    xdotool key ctrl+alt+w
  fi
fi
