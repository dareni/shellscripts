#!/bin/env bash
#
# Config:
#   $ sudo apt install rclone 
#   $ rclone config
#   Config rclone:
#   -Type n for "New remote".
#   -Name it gdrive.
#   -When asked for storage type, look for Google Drive
#    18 
#   -Add client_id and client_secret
#   -Select scope 1 (Full access to all files).
#   -service_account_file blank
#   -Edit advanced config? n
#   Use auto config y
#   Configure this as a shared drive n
#   Keep this gdrive remote y
#   q

# test with $ rclone lsf gdrive:

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration (Matches the name you gave in 'rclone config')
REMOTE_NAME="gdrive"
REMOTE_DIR="bup"

# Check if a file argument was provided
if [ -z "$1" ]; then
    echo "Usage: $0 /path/to/your/file.ext"
    exit 1
fi

FILE_PATH="$1"

# Verify the local file actually exists
if [ ! -f "$FILE_PATH" ]; then
    echo "Error: File '$FILE_PATH' does not exist." >&2
    exit 1
    fi

FILENAME=$(basename "$FILE_PATH")
echo "Uploading '$FILENAME' to the root of Google Drive..."

# rclone copy /path/to/file remote:
# Leaving the section after the colon blank specifies the root directory.
rclone copy "$FILE_PATH" "${REMOTE_NAME}:$REMOTE_DIR" --progress

echo "Success! '$FILENAME' pushed '$REMOTE_DIR'  Google Drive."
