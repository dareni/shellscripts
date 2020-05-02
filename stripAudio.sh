#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
if  [ "$1" = "" ]; then
  echo "Strip the audio to an mp3."
  echo "Usage: ./stripAudio.sh ../*webm"
  echo "       ./stripAudio.sh song.avi"
else
  MENCODER=`which mencoder` 
  FFMPEG=`which ffmpeg`
  for FILE in "$@"
  do
    FILENOPATH="${FILE##*/}"
    FILENOEXT="${FILENOPATH%.*}"
    OUTFILE="$FILENOEXT.mp3"
    echo infile: "$FILE" outfile: "$OUTFILE"
    if [ -n "$MENCODER" ]; then
      mencoder $FILE  -ovc frameno -oac mp3lame -of rawaudio -lameopts cbr:br=128 -o $OUTFILE
    elif [ -n "$FFMPEG" ]; then
      ffmpeg -i "$FILE" -vn -acodec copy "$FILENOEXT.ogg"
    else
      echo echo mencoder and ffmpeg not installed.
    fi;
    echo done
  done;
fi;


