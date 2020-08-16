#!/bin/sh

DAY=`date +'%y%m%d'`
LOGDIR=/var/log/ut
mkdir -p $LOGDIR
OUT=$LOGDIR/$DAY.log

awk '{
  if (// || //){
  } else if (/\^1/ || /\^4/) {
    if ($0 !~ /\^7/ ) {
      print $0
      fflush()
    }
  } else if (/\console:/ && (/Attack/ || /attack/ || /Upcoming/)) {
      print $0
      fflush()
  } else if (/connected/ || /joined/ || /overflow/ || /\^5[auth]/) {
      print $0
      fflush()
  } else if (/console_tell:/) {
    if (/XLR Stats:/ || /Ratio/) {
      print $0
      fflush()
    }
  }

}' >> $OUT /dev/stdin
