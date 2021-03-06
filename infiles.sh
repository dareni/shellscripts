#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
if [ -z "$1" ]; then
    echo Usage: infiles.sh search_pattern filetype 
    echo filetype war jar zip
    exit 1;
fi

SEARCH_PATTERN=$1

if [ -z "$2" ]; then
    FILETYPE=jar
else
    FILETYPE=$2
fi

#    find . -name "*.$FILETYPE" -exec jar -tvf {} \; |grep -H $SEARCH_PATTERN
#| grep -H -i 
#    exit 0;;

for f in `find . -name "*.$FILETYPE"`; 
do  
    count=0
    case $FILETYPE in
        war|jar)
            count=`jar -tvf $f |grep -c -i "$SEARCH_PATTERN"`;;
        zip)
            count=`unzip -l $f |grep -c -i "$SEARCH_PATTERN"`;;
        *)
            count=`grep -c -i "$SEARCH_PATTERN" $f`;;
    esac

    if [ $count -gt 0 ]; then
        echo $count $f;
    fi

done;

