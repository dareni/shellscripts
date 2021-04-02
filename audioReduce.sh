# vim:ts=2:sw=2:et:

MATCH="$1"
TEST="$2"

COUNT=`ls |grep -c $MATCH`

echo
echo $COUNT files match.

TEMP_SEP="$IFS"
SEP=$(echo -en '\n\b')
IFS="$SEP"

for name in `ls -1|grep $MATCH`
do
   IFS="$TEMP_SEP"
   EXT=${name##*.}
   FILENAME=${name%%.*}
   OP="${FILENAME}_r.$EXT"

   if [ "$TEST" = "n" ]; then
     echo Doing conversion: ffmpeg -i $name -vn -ab 30k -ar 22050 "$OP"
     ffmpeg -i $name -vn -ab 30k -ar 22050 "$OP" >> op.log
   else
     echo Doing conversion "$name -> $OP"
   fi
   IFS="$SEP"
done

IFS="$TEMP_SEP"

