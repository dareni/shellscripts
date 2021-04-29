#!/bin/sh
#
usage() {
    cat <<EOF
  Pdf file opener.

  openPdfs.sh [-k] [FILE]...

  FILE may be:
      - filenames ie filename1 filename2...
      - GLOB patterns ie A*pdf B*pdf

  -k  keep open all files on screen. Without -k each file open and close is
      sequential.

EOF
}

MUPDF=`which mupdf`
if [ ! -x "$MUPDF" ]; then
  echo mupdf is not installed.
  exit;
fi

if [ "$#" -eq 1 -o "$#" -eq 0 ]; then
  if [ "$1" = "-k" ]; then
    for file in `ls -1v *pdf`; do
      if [ "$file" !=  "-k" ]; then
        mupdf "$file"&
      fi
    done;
  elif [ "$#" -eq 0 ]; then
    FCOUNT=`ls -1 |grep pdf$ |wc -w`
    if [ 0 -eq $FCOUNT ]; then
      usage
      exit
    else
      for file in `ls -1v *pdf`; do mupdf "$file"; done;
    fi
  else
    for file in `ls -1v "$@"`; do mupdf "$file"; done;
  fi
else
  if [ "$1" = "-k" ]; then
    for file in `ls -1v "$@"`; do
      if [ "$file" !=  "-k" ]; then
        mupdf "$file"&
      fi
    done;
  else
    for file in `ls -1v "$@"`; do mupdf "$file"; done;
  fi

fi

# vim: ts=2 sw=2 et tw=78 ft=sh fdm=marker:
