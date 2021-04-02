# vim:ts=2:sw=2:et:

MATCH="$1"
TEST="$2"

COUNT=`ls |grep -c $MATCH`

echo
echo $COUNT files match.

TEMP_SEP="$IFS"
SEP=$(echo -en '\n\b')
IFS="$SEP"
CMD="concat:"

for name in `ls -1|grep $MATCH`
do
   IFS="$TEMP_SEP"
   CMD="${CMD}${name}|"
   IFS="$SEP"
done

IFS="$TEMP_SEP"

if [ "$TEST" = "n" ]; then
  echo Runnin cmd: ffmpeg -i \"$CMD\" -c copy output.mp3
  ffmpeg -i \"$CMD\" -c copy output.mp3
else
  echo Conversion cmd: ffmpeg -i \"$CMD\" -c copy output.mp3
fi


