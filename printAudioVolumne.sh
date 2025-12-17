#!/bin/bash

if [ $# -eq 0 ]; then
  echo "Usage: $0 <file1> [<file2> ...]"
  exit 1
fi

for music_file in "$@"; do
  if [ -f "$music_file" ]; then
    volume=$(ffmpeg -i "$music_file" -af "volumedetect" -vn -sn -dn -f null - 2>&1 | grep mean_volume: | awk '{ print $(NF-1) $NF}')
    echo "${music_file:0:25}: $volume"
  else
    echo "Error: File not found or is not a regular file: $music_file"
  fi
done
