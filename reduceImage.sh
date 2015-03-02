# Maintained at: git@github.com:dareni/shellscripts.git
EXT=${1##*.}
FILENAME=${1%%.*}
convert -geometry 682x511 -quality 50 $1 ${FILENAME}_r.${EXT} 
