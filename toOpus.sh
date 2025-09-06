# !/bin/env sh
# Clean mpeg files.
# Use opus over mp3 or mp4 because of the superiour bandwidth efficiency.
#
# Bulk convert:
#   find . -name "*.mp4" -exec toOpus.sh {} \;

NAME="$1"
NAME_PREFIX="${NAME%.*}"
OUTPUT_NAME="${NAME_PREFIX}.opus"
echo $NAME_PREFIX

INPUT_SIZE=$(du -b "$NAME" | cut -f 1)

BITRATE=$(ffmpeg -i "$1" -f null /dev/null 2>&1 | grep bitrate: | cut -d: -f 6 | cut -dk -f 1)
BITRATE=$(echo $BITRATE | tr -d '[:space:]')
ERROR=$(echo $BITRATE | grep '[^0-9]')
if [ -n "$ERROR" ]; then
  echo -e "\n\nCould not determine bitrate?? error: $ERROR"
  return
fi
if [ -z "$BITRATE" ]; then
  echo -e "\n\nCould not determine bitrate??"
  return
fi

ffmpeg -i "$NAME" -b:a ${BITRATE}k "$OUTPUT_NAME"
OUTPUT_SIZE=$(du -b "$OUTPUT_NAME" | cut -f 1)

if [ $OUTPUT_SIZE -gt $INPUT_SIZE ]; then
  echo -e "\n\n Error New file is larger in size?"
fi
