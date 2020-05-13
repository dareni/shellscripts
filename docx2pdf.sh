# Require pandoc texlive-latex-recommended texlive-fonts-recommended
FILE=$1
FILENOPATH=${FILE##*/}
FILENOEXT=${FILENOPATH%.*}

if [[ -z "$FILE" ]]; then
  echo Usage: docx2pdf filename.docx
else
  pandoc -o "$FILENOEXT.pdf" -f docx "$FILE"
fi
