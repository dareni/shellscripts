#!/bin/sh
# Send a mail to root when the disk usage passes a threshold.
# Usage: diskcheck.sh [filesystem] [threshold%]

if [ -z "$1" ]; then
    FS="/"
else
    FS="$1"
fi

if [ -z "$2" ]; then
    THRESHOLD=98
else
    THRESHOLD=$2
fi

CAPACITY=`df ${FS} | awk '{ if (NR == 2) print $5}' |sed 's/%//'`

if [ ${CAPACITY} -ge ${THRESHOLD} ]; then
   echo "`hostname` ${FS} file system usage ${CAPACITY}%" | mail -s "$FS file system usage ${CAPACITY}%" root
fi

