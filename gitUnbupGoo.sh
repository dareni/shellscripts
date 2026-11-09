#!/bin/env bash
echo Select a git bundle for extraction.
echo Non bundle files will download and extract and error on bundle veryify.

rclone ls gdrive:bup | head

UNBUP_TMP=/tmp
SOURCE_GPG=$1

if [ -z "$SOURCE_GPG" ]; then
  echo "no gdrive source file specified"
  exit 0
fi

rclone copy gdrive:bup/$SOURCE_GPG $UNBUP_TMP

echo "expecting a password now!"
echo "usage: echo a_pass_key | unbupGoo.sh bup.file.gz.gpg"

PASSWORD="$(cat)"

gitUnbup.sh "$SOURCE_GPG" "$PASSWORD" "$UNBUP_TMP"
