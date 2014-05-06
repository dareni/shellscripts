#!/bin/sh
if  [ "$1" = "" ]; then
    echo "Strip the audio to an mp3."
    echo "Usage: ./stripAudio.sh ../*webm"
    echo "       ./stripAudio.sh song.avi"
else
    for FILE in $@
    do
        FILENOPATH=${FILE##*/}
        FILENOEXT=${FILENOPATH%.*}
        OUTFILE=$FILENOEXT.mp3
        echo infile: $FILE outfile: $OUTFILE
    mencoder $FILE  -ovc frameno -oac mp3lame -of rawaudio -lameopts cbr:br=128 -o $OUTFILE
    done;
fi;


