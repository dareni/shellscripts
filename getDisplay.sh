#!/usr/bin/env sh
# Get the value of current first active DISPLAY.
# Maintained at: git@github.com:dareni/shellscripts.git

#w -h |awk '{print $3}' |grep : |sort -u
displays=`w -h |awk '{print $3}' |grep : |sort -u`

for d in $displays 
do
  DISPLAY=$d
  export DISPLAY
  if timeout 1s xset q >/dev/null; then
    echo $d
    exit 0;
  fi
done;
echo "No X servers at [$displays]" >&2
exit 1;
