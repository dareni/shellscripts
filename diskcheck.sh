#!/bin/sh
# Send a mail to root when the disk usage passes a threshold.
# Usage: diskcheck.sh [filesystem] [threshold%]
# Usage: diskcheck.sh [filesystem1:filesystem2] [threshold%]

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

CAP_MSG=""
for FSYS in `echo $FS  |sed 's/:/ /g'`
do
    CAPACITY=`df ${FSYS} | awk '{ if (NR == 2) print $5}' |sed 's/%//'`
    if [ ${CAPACITY} -ge ${THRESHOLD} ]; then
        CAP_MSG="${CAP_MSG}$FSYS usage: $CAPACITY%\n"
    fi
done;

if [ -n "$CAP_MSG" ]; then
    echo "WARNING: `hostname` filesystem usage threshold ${THRESHOLD}% exceeded!\n\n$CAP_MSG" | mail -s "`hostname` filesystem usage threshold ${THRESHOLD}% exceeded." root 
fi;
