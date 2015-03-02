#!/usr/local/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git

do_usage(){
   echo "usage:  rdiff.sh <[user@]remotehost> </path/localfile> [</path/remotefile>]"
}

if [[ "$1" = "" ]]; then
   do_usage;
   exit;
fi

LOCALFILE=$2
REMOTEHOST=$1
   
if [[ "$3" = "" ]]; then
   REMOTEFILE=$2
else 
   REMOTEFILE=$3
fi

echo "ssh ${REMOTEHOST} \"cat $REMOTEFILE\" | diff - $LOCALFILE "
ssh ${REMOTEHOST} "cat $REMOTEFILE" | diff - $LOCALFILE 
