#!/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if the current directory is a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: This directory is not a Git repository." >&2
    exit 1
fi

# Get the name of the current directory
DIR_NAME=$(basename "$PWD")

# Get the current date in YYYY-MM-DD format
CURRENT_DATE=$(date +%Y-%m-%d)

# Construct the bundle filename
BUNDLE_NAME="${DIR_NAME}_${CURRENT_DATE}.bundle"

echo "Creating Git bundle: ${BUNDLE_NAME}..."

# Create the bundle. 
# Using --all tracks all branches. Change to 'main' or 'master' if you only want one.
#
BUNDLE_TMP_DIR="/tmp"
GIT_VERIFY_REPO="$BUNDLE_TMP_DIR/git-bundle_verify"
BUNDLE_ABS_NAME=$BUNDLE_TMP_DIR/${BUNDLE_NAME}
git bundle create $BUNDLE_ABS_NAME --all

mkdir $GIT_VERIFY_REPO && cd $GIT_VERIFY_REPO && git init && git bundle verify $BUNDLE_ABS_NAME; cd - && rm -rf $GIT_VERIFY_REPO

gzip $BUNDLE_ABS_NAME
BUNDLE_ABS_NAME_GZ=$BUNDLE_ABS_NAME.gz
HASH=$(md5sum $BUNDLE_ABS_NAME_GZ | cut -d' ' -f1)
BUNDLE_HASH_NAME="$BUNDLE_TMP_DIR/${DIR_NAME}_${CURRENT_DATE}.$HASH.bundle.gz"
export BUNDLE_HASH_NAME
mv $BUNDLE_ABS_NAME_GZ $BUNDLE_HASH_NAME 
echo NOTE: hash is dependant on the internal bundle timestamp!
export BUNDLE_HASH_NAME
