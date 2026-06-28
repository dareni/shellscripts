#!/bin/env bash
#
# Backup a git repo to google drive.
# Execute from within the repo.

echo "expecting password now!"
echo "usage echo a_pass_key | bupGoo.sh"
PASSWORD="$(cat)"

if [ -z "$PASSWORD" ]; then
  echo "Empty password piped?"
fi

source ~/bin/shellscripts/bundle.sh

gpg --batch --yes --passphrase "$PASSWORD" \
  --s2k-cipher-algo aes256 \
  --s2k-digest-algo sha512 \
  -c  $BUNDLE_HASH_NAME

putGooDrive.sh $BUNDLE_HASH_NAME.gpg
