#!/bin/sh

if [ -z "$1" ]; then
  echo server:  vidStream.sh hostip filename
  echo client:  vidStream.sh hostip
elif [ -z "$2" ]; then
  #nc 192.168.1.11 5500 |mplayer -cache 8192 -
  nc $1 5500 |mplayer -cache 8192 -
else
  echo server listening for connection ....
  #nc -l -p 5500 192.168.1.11 < v.mp4.crdownload
  nc -l -p 5500 $1 < $2
fi

