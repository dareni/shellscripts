# vim:ts=2:sw=2:et:

if [ -z $2 ]; then

echo Usage:
echo       ./rename match replacement test
echo       match - no wild char grep text for filename matching.
echo       replacement - the replacement text for the match text of the filename.
echo       test - blank for test, else 'n' to execute the rename.

fi

MATCH="$1"
REPLACEMENT="$2"
TEST="$3"

COUNT=`ls |grep -c $MATCH`

echo
echo $COUNT files match.

TEMP_SEP="$IFS"
SEP=$(echo -en '\n\b')
IFS="$SEP"

for name in `ls -1|grep $MATCH`
do
   IFS="$TEMP_SEP"
   ADJ=`echo $name |sed 's/'$MATCH'/'$REPLACEMENT'/'`
   if [ "$TEST" = "n" ]; then
     echo Doing rename "$name -> $ADJ"
     mv "$name" "$ADJ"
   else
     echo mv "$name -> $ADJ" ?
   fi
   IFS="$SEP"
done

IFS="$TEMP_SEP"

