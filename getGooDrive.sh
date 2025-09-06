#!/usr/bin/env sh

# Download a file from google drive.
#

# fileid="1afaPxruOGU4C8ws3cQFzD__JdlV4Ynd4"
# filename="file.zip"
# curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${fileid}" >/dev/null
# curl --insecure -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=$(awk '/download/ {print $NF}' ./cookie)&id=${fileid}" -o ${filename}

# Get files from Google Drive
#https://drive.google.com/file/d/1afaPxruOGU4C8ws3cQFzD__JdlV4Ynd4/view?usp=drive_link

FILE_NAME=$1
if [ -z "$FILE_NAME" ]; then
  echo
  echo " NAME                                    "
  echo "      getGooDrive.sh                     "
  echo "                                         "
  echo " SYNOPSIS                                "
  echo "      getGooDrive.sh [filename]          "
  echo "                                         "
  echo " DESCRIPTION                             "
  echo "      Download a file from google drive. "
  echo "      The clipboard must contain a URL to"
  echo "      a file on google drive. The file   "
  echo "      must have general access for anyone"
  echo "      with the link. Directory download  "
  echo "      is not supported.                  "
  echo
  exit 1
fi

if ! command -v xclip >/dev/null 2>/dev/null; then
  echo "xclip is not installed"
  exit 1
fi

# URL is a link to a google drive file of  the form :
# "https://drive.google.com/file/d/1afaPxruOGU4C8ws3cQFzD__JdlV4Ynd4/view?usp=drive_link"
URL=$(xclip -o)
if [ -z "$URL" ]; then
  echo "Clipboard is empty. Please select the url for the file."
  exit 1
fi

#FILE_ID="1afaPxruOGU4C8ws3cQFzD__JdlV4Ynd4"
FILE_ID=$(echo $URL | cut -d '/' -f6)

echo "FILE_ID: $FILE_ID"
echo "URL: $URL"
read -p "Is this correct? Continue? (y/N): " CONT

if [ "y" != "$CONT" ]; then
  exit 1
fi

if [ -z $FILE_ID ]; then
  echo "Could not determine FILE_ID"
  exit 1
fi

wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate $URL -O- >/dev/null
wget --load-cookies /tmp/cookies.txt "https://drive.usercontent.google.com/download?id=$FILE_ID&export=download&confirm=t" -O $FILE_NAME
