#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
if  [ "$1" = "" ]; then
  echo "Strip the audio to an mp3."
  echo "Usage: ./stripAudio.sh ../*webm"
  echo "       ./stripAudio.sh song.avi"
else
  #MENCODER=`which mencoder`
  if [ ! -x "`which ffmpeg`" ]; then
    echo Please install ffmpeg.
    exit
  fi

  for FILE in "$@"
  do
    FILENOPATH="${FILE##*/}"
    FILENOEXT="${FILENOPATH%.*}"
    OUTFILE="$FILENOEXT.ogg"
    echo InFile:"'$FILE'"
    echo OutFile:"'$OUTFILE'"
    #mencoder $FILE  -ovc frameno -oac mp3lame -of rawaudio -lameopts cbr:br=128 -o $OUTFILE
    ffmpeg -i "$FILE" -vn -acodec libvorbis "$OUTFILE"
  done;
fi;
