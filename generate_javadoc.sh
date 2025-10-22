#Generate javadoc from giver src.zip
SRC_FILE=$1
TMP_SRC_DIR="/tmp/jdk_tmp_src"
JDOC_TMP_DIR="/tmp/javadoc_tmp"
JDOC_FILE="/tmp/javadoc.jar"

if [[ ! -f $SRC_FILE ]]; then
  echo Source "'$SRC_FILE'" does not exist.
  echo Enter the location of a valid jdk/lib/src.zip
  exit
fi

if [[ -d "$JDOC_TMP_DIR" ]]; then
  echo $JDOC_TMP_DIR exists?
  exit
fi

if [[ -d "$TMP_SRC_DIR" ]]; then
  echo $TMP_SRC_DIR exists?
  exit
fi

if [[ -d "$JDOC_FILE" ]]; then
  echo $JDOC_FILE exists?
  exit
fi

mkdir $JDOC_TMP_DIR
mkdir $TMP_SRC_DIR
unzip $SRC_FILE -d /tmp/jdk_tmp_src
if [[ $? != 0 ]]; then
  echo Failure: unzip $SRC_FILE -d $TMP_SRC_DIR
  exit
fi

javadoc -d $JDOC_TMP_DIR --module-source-path $TMP_SRC_DIR --module $(ls -1 $TMP_SRC_DIR | sed -z -e "s/\n/,/g")

jar -cvf $JDOC_FILE -C $JDOC_TMP_DIR .
if [[ $? != 0 ]]; then
  echo Failure: jar -cvf $JDOC_FILE -C $JDOC_TMP_DIR
  exit
fi

rm -rf $JDOC_TMP_DIR
rm -rf $TMP_SRC_DIR

echo
echo javadoc generation complete:
ls -l $JDOC_FILE
