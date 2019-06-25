#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
# Convert svg to png.
# -s size in pixels default 64.
# eg convertSvg.sh -s 64 *.svg

LIST=$@
ARG1=`echo $LIST |cut -d" " -f1`
if [ "$ARG1" = "-s" ]; then
  SIZE=`echo $LIST |cut -d" " -f2`
  LIST=`echo $LIST |cut -d" " -f3-`
else
  SIZE=64
fi

for file in $LIST
do
  NAME=`echo $file |cut -d. -f1`
  inkscape -z -e $NAME.png -w $SIZE -h $SIZE $NAME.svg
done;
