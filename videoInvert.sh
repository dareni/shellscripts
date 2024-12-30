NAME=$1
ANGLE=$2
if [ -z "$ANGLE" ]; then
cat <<HEREDOC

  videoInvert.sh <filename> <angle>

  where angle is the rotation in degrees.

HEREDOC
  exit -1
fi

#   0=90 ccw and vertical flip (default)
#   1=90 cw
#   2=90 ccw
#   3=90 clockwise and vertical flip

PREFIX=${NAME%\.*}
EXT=${NAME##*.}
OP_NAME=${PREFIX}_flip.$EXT
read -p "Output filename is: $OP_NAME"

#ffmpeg -i $NAME  -vf "transpose=1" $OP_NAME
#ffmpeg -i $NAME  -vf "rotate=PI/2" $OP_NAME
ffmpeg -i $NAME -c copy -metadata:s:v:0 rotate=$ANGLE $OP_NAME

#display rotation without re-encode
#ffmpeg -display_rotation 90 -i $NAME -codec copy $OP_NAME
#ffmpeg -i $NAME -map_metadata 0 -metadata:s:v rotate=90 -codec copy $OP_NAME
