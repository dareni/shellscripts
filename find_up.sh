#!/bin/sh
#From http://unix.stackexchange.com/questions/6463/find-searching-in-parent-directories-instead-of-subdirectories

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

FIND=`which find`
PWD=`which pwd`
#Clear the PATH to allow find execution of pwd.
OLDPATH=$PATH
PATH=""
$FIND $path -name $1 -execdir $PWD \;
PATH=$OLDPATH
