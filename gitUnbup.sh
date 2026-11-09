#!/bin/env bash
# Extract an encrypted git bundle.
# A non bundle file will decrypt but will fail the bundle verify.

SOURCE_GPG=$1
PASSWORD=$2
UNBUP_TMP=$3

if [ -z "$UNBUP_TMP" ]; then
  UNBUP_TMP="/tmp"
fi

SOURCE_GZ="${SOURCE_GPG%.gpg}"
BUNDLE="${SOURCE_GZ%.gz}"
REPO_NAME="${BUNDLE%.bundle}"
BUNDLE_ABS="$UNBUP_TMP/$BUNDLE"

if [ ! -f "$UNBUP_TMP/$SOURCE_GPG" ]; then
  cp $SOURCE_GPG $UNBUP_TMP/$SOURCE_GPG
fi

if [ -z "$PASSWORD" ]; then
  echo "expecting a password now!"
  echo "usage: echo a_pass_key | unbupGoo.sh bup.file.gz.gpg"
  PASSWORD="$(cat)"
fi

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
mkdir $GIT_VERIFY_REPO && cd $GIT_VERIFY_REPO &&
  git init && git bundle verify $BUNDLE_ABS

printf "create git workdir in %s /(y/n): " "$OLDPWD"
read CONTINUE </dev/tty

cd - && rm -rf $GIT_VERIFY_REPO

if [ y != "$CONTINUE" -a Y != "$CONTINUE" ]; then
  exit 0
else
  mkdir $REPO_NAME && cd $REPO_NAME &&
    git init && git clone $BUNDLE_ABS
fi
