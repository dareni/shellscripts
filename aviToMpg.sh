NAME=$1
PREFIX=${NAME%\.*}
OUT="$PREFIX.mp4"
#ffmpeg -i "$NAME" -strict -2 "$OUT"
#
#Constant Rate Factor (crf).
#The values will depend on which encoder you're using.
#For x264 your valid range is 0-51:
#The range of the quantizer scale is 0-51 where:
# 0 is lossless,
# 23 is default,
# and 51 is worst possible.
# A lower value is a higher quality and a subjectively sane range is 18-28
#
ffmpeg -i $NAME -c:v libx265 -crf 20 -preset veryslow  -c:a aac -b:a 128k -ac 2 $OUT
