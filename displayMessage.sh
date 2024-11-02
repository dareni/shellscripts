#!/usr/bin/env sh
# Open an x window to display a message.
# Maintained at: git@github.com:dareni/shellscripts.git
DISPLAY=`getDisplay.sh`
export DISPLAY
TITLE=title
MESSAGE=message
TITLE="$1"
MESSAGE="$2"

fail() {
  TITLE="getDisplay.sh error"
  echo "$TITLE: '$1'" >&2
  xterm  -fa *courier* -fs 10 -bg black -fg white -T "$TITLE" -hold -e echo -e "$1" &
}

if [ -z "`which yad`" ]; then
  fail "Please install yad. $MESSAGE"
  exit 1
fi

yad --title="$TITLE"  --text "$MESSAGE" --escape-ok --sticky --center --on-top --borders=15


