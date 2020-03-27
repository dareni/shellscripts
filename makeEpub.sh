#!/bin/sh
LANG=C

#Dependencies:pandoc2.9 texlive-fonts-recommended texlive-xetex
VERSION=`pandoc -v |head -1|cut -d" " -f2`
VERSION_MAJOR=`echo $VERSION |cut -d"." -f1`
VERSION_MINOR=`echo $VERSION |cut -d"." -f2`

if [ "$VERSION_MAJOR" -lt 2 ] ||  [ "$VERSION_MAJOR" -eq 2 -a  "$VERSION_MINOR" -lt 9 ]; then
  echo Pandoc minimum version 2.9 required. Detected version: $VERSION
  exit
fi

CMD=$1
if [ -z "$CMD" ]; then
  echo "Usage: ./makehtml.sh img|epub"
  exit
fi

echo Working in dir `pwd` ...
JPG_COUNT=`ls -1 *jpg |wc -l`
FILE_COUNT=`cat count`

if [ -z "$FILE_COUNT" ] || [ "$FILE_COUNT" = 0 ]; then
  echo No jpg \"count\" file in the working directory?
  exit
fi

if [ -z "$JPG_COUNT" ] || [ "$JPG_COUNT" = 0 ]; then
  echo No jpg files?
  exit
fi

if [ $JPG_COUNT -ne $FILE_COUNT ]; then
  echo The jpg \"count\" file does not match the number of jpg files?
  exit
fi

PARA_OPEN="<p>"
#PARA_CLOSE tag must be printed at the end of a line only
#  because an image may be printed after it.
PARA_CLOSE="</p>"
IMG_TAG="<img"
BREAK_TAG="<br/>"

IMG_DIR=img
mkdir -p $IMG_DIR
MOD_DIR=html_mod
mkdir -p $MOD_DIR
FRONT_COVER=$IMG_DIR/front.jpg
TXT_DIR=txt
mkdir -p $TXT_DIR
HTML_DIR=html
mkdir -p $HTML_DIR
EPUB_CSS="epub.css"

makeEpubCss() {
cat <<HEREDOC > $EPUB_CSS
/* This defines styles and classes used in the book */
body { margin: 5%; text-align: justify; font-size: medium; }
code { font-family: monospace; }
h1 { text-align: left; }
h2 { text-align: left; }
h3 { text-align: left; }
h4 { text-align: left; }
h5 { text-align: left; }
h6 { text-align: left; }
h1.title { }
h2.author { }
h3.date { }
ol.toc { padding: 0; margin-left: 1em; }
ol.toc li { list-style-type: none; margin: 0; padding: 0; }
a.footnote-ref { vertical-align: super; }
em, em em em, em em em em em { font-style: italic;}
em em, em em em em { font-style: normal; }
.aligncenter { text-align:center; }
.small { font-size: small};
HEREDOC
}

doCreateHtml() {
  cat txt/$PGNO.txt |iconv -f utf-8 -t ascii//TRANSLIT | awk \
     'BEGIN{paragraph=0; blank=0; fullstop=0}
      {
        if ($0 !~ /[a-z]/) {
           #Get lines without lowercase.
           if ($0 ~ /[A-Z]/) {
             #Must be all uppercase.
             if (NR == 1) {
               #All caps first line so treat as heading.
               print "<h1>"$0"</h1><br/>"
             } else {
               #All caps on a line so force a break.
               print $0"<br/>"
               blank=0
             }
           } else {
            #No a-z no A-Zupper.
            #remove spaces and control chars
            gsub(/[ \x00-\x1F\x7F]/,"",line);
            #check for blankline
            if (length(line) == 0) {
              blank=1
              if (paragraph == 1 && fullstop == 1) {
                 print "'$PARA_CLOSE'"
                 paragraph = 0
                 fullstop = 0
              }
             }
           }
        } else {
          #Line has lower case chars.
          #Not a blank must be text.
          startChar = substr($0,1,1)
          if (NR == 1) {
            if (startChar  ~ /[\x22\x27\x40A-Z]/) {
              print "'$PARA_OPEN'"$0
              paragraph = 1
            }  else if (startChar  ~ /[a-z]/) {
              paragraph = 1
              print $0
            } else {
              print $0
            }
          }else if (blank == 1) {
            if (paragraph == 0 && (startChar  ~ /[\x22\x27\x40A-Z]/)) {
              print "'$PARA_OPEN'"$0
              paragraph = 1
            } else {
              print $0
            }
            blank = 0
          } else {
            print $0
          }
          endChar = substr($0,length($0),1)
          #treat fullstop as . or ? or single or double quote.
          if (endChar  ~ /[\x2e\x3f\x22\x27\x40]/) {
            fullstop=1
          } else {
            fullstop=0
          }
        }
      }
      END {
        if (paragraph == 1 && fullstop == 1) {
         print "'$PARA_CLOSE'"
        }
      }
     ' >  $HTML_OP_FILE

}
if [ "$CMD" = "test" ]; then
  PGNO=$2
  HTML_OP_FILE=$3
  doCreateHtml
  echo output1: $HTML_OP_FILE
  exit
elif [ "$CMD" = "img" ]; then

  echo Click top left image corner ...
  WINID=`xdotool selectwindow`
  MOUSELOC=`xdotool getMouselocation`
  MOUSEX1=`echo $MOUSELOC|cut -d" " -f1|cut -d: -f2`
  MOUSEY1=`echo $MOUSELOC|cut -d" " -f2|cut -d: -f2`
  echo Click bottom right image corner ...

  WINID=`xdotool selectwindow`
  MOUSELOC=`xdotool getMouselocation`
  MOUSEX2=`echo $MOUSELOC|cut -d" " -f1|cut -d: -f2`
  MOUSEY2=`echo $MOUSELOC|cut -d" " -f2|cut -d: -f2`

  WIDTH=$(($MOUSEX2-$MOUSEX1))
  HEIGHT=$(($MOUSEY2-$MOUSEY1))

  read -p "Enter the page number: " PGNO
  read -p "Enter the image text: " IMG_TXT

  IMG_FILENAME=$IMG_DIR/$PGNO
  mkdir -p $IMG_FILENAME
  IMG_COUNT=`ls -1 $IMG_FILENAME |wc -l`
  IMG_FILENAME=$IMG_FILENAME/$(($IMG_COUNT+1)).jpg

  import -window root -quality 100 -crop \
    ${WIDTH}x${HEIGHT}+${MOUSEX1}+${MOUSEY1} $IMG_FILENAME

    if [ -n "$IMG_TXT" ]; then
      IMG_TXT="<italic>$IMG_TXT</italic>"
    fi
    IMAGE_TAG_COMPLETE=${IMG_TAG}' src="'$IMG_FILENAME'">'${BR_TAG}${IMG_TXT}

    HTML_OP_FILE="html/$PGNO.html"
    HTML_OP_FILE_MOD="$MOD_DIR/${PGNO}.html"

    if [ ! -e $HTML_OP_FILE_MOD ]; then
      if [ ! -e $HTML_OP_FILE ]; then
        touch $HTML_OP_FILE_MOD
      else
        cp $HTML_OP_FILE $HTML_OP_FILE_MOD
      fi
    fi

    # Append the image to the file.
    echo $IMAGE_TAG_COMPLETE >> $HTML_OP_FILE_MOD

elif [ "$CMD" = "epub" ]; then

  if [ ! -e "$FRONT_COVER" ]; then
    read -p "What page(number) is the front cover? " FCP
    cp $FCP.jpg $FRONT_COVER
  fi

  METADATA="metadata.yml"
  if [ ! -e "$METADATA" ]; then
    read -p "What is the title? " B_TITLE
    read -p "What is the author? " B_AUTHOR
    echo "---\ntitle: '$B_TITLE'\nauthor:\n- '$B_AUTHOR'\nlanguage: en-US\n..." > $METADATA
  fi

  if [ ! -e ./$EPUB_CSS ]; then
    makeEpubCss
  fi

  PANDOC_CMD="pandoc -f html -t epub2 --css=./$EPUB_CSS \
  -o book.epub  --epub-cover-image=$FRONT_COVER --metadata-file=$METADATA"

  for FILE in `ls -v *.jpg`
  do
    FILENOPATH=${FILE##*/}
    PGNO=${FILENOPATH%.*}
    HTML_OP_FILE="html/$PGNO.html"
    HTML_OP_FILE_MOD="$MOD_DIR/${PGNO}.html"

    if [ ! -e "txt/$PGNO.txt" ]; then
      echo Creating txt/$PGNO.txt ...
      tesseract $FILE stdout >txt/$PGNO.txt
    fi

    SIZE=`stat -c %s txt/$PGNO.txt`
    if [ "$SIZE" -gt 1 ]; then
      if [ ! -e $HTML_OP_FILE ]; then
        doCreateHtml
      fi
    fi

    if [ -e $HTML_OP_FILE_MOD ]; then
      FILE_TO_ADD=$HTML_OP_FILE_MOD
    elif [ -e $HTML_OP_FILE ]; then
      FILE_TO_ADD=$HTML_OP_FILE
    else
      FILE_TO_ADD=""
    fi

    if [ -n $FILE_TO_ADD ]; then
      PANDOC_CMD="$PANDOC_CMD $FILE_TO_ADD"
    fi

  done
  echo $PANDOC_CMD
  `$PANDOC_CMD`
fi


