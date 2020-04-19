# Require libreoffice
FILE=$1 FILENOPATH=${FILE##*/} FILENOEXT=${FILENOPATH%.*}

if [[ -z "$FILE" ]]; then
  echo Usage: pptx2pdf filename.pptx
else
  soffice --convert-to pdf $FILE
fi
