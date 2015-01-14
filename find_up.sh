#!/bin/sh
#From http://unix.stackexchange.com/questions/6463/find-searching-in-parent-directories-instead-of-subdirectories
#Find a file in a parent directory.

if [ -z "$2" ]; then
    path="."
else
    path=$2
fi

path=`readlink -f $path`

dot=""
while [ "$path" != "" -a ! -e "$path/$1"  -a "$path" != "$dot" ]; do
    dot=$path
    path=${path%/*}
done

if [ -n "$path" ]; then
  echo $path
fi

