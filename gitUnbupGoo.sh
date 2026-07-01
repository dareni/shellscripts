#!/bin/env bash

rclone ls gdrive:bup |head

UNBUP_TMP=/tmp
SOURCE_GPG=$1
SOURCE_GZ="${SOURCE_GPG%.gpg}"
BUNDLE="${SOURCE_GZ%.gz}"
BUNDLE_ABS="$UNBUP_TMP/$BUNDLE"
if [ -z "$SOURCE_GPG" ]; then
  echo "no gdrive source file specified"
  exit 0
fi

rclone copy gdrive:bup/$SOURCE_GPG $UNBUP_TMP

echo "expecting a password now!"
echo "usage: echo a_pass_key | unbupGoo.sh bup.file.gz.gpg"

PASSWORD="$(cat)"

if [ -z "$PASSWORD" ]; then
  echo "empty piped password?"
fi

echo decrypt $SOURCE_GPG to $SOURCE_GZ

gpg --batch --yes --passphrase "$PASSWORD" \
-o $UNBUP_TMP/$SOURCE_GZ -d $UNBUP_TMP/$SOURCE_GPG

echo md5sum:
md5sum $UNBUP_TMP/$SOURCE_GZ
rm $UNBUP_TMP/$SOURCE_GPG
gunzip $UNBUP_TMP/$SOURCE_GZ

echo verify $BUNDLE_ABS
GIT_VERIFY_REPO="$UNBUP_TMP/git-bundle_verify"
mkdir $GIT_VERIFY_REPO  && cd $GIT_VERIFY_REPO \
  && git init && git bundle verify $BUNDLE_ABS;
cd - && rm -rf $GIT_VERIFY_REPO
