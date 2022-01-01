#!/usr/bin/env sh

PORT=$1

VERS=`python -V 2>&1 |sed -e "s/[[:space:]]/ /g" |awk \
 '{
   version = $0;
   split(version, arr, " ");
   split(arr[2], arr, ".");
    print arr[1]
 }'`

if [ $VERS -ge 3 ]; then
  python -m http.server $PORT
else
  python -m SimpleHTTPServer $PORT
fi
