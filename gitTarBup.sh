#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
echo "gitTarBup.sh: \n
From the current git directory copy each modified file into a tar.
"

git status --porcelain .

read -p "Continue (y/n): " CONTINUE


if [ y != "$CONTINUE" -a Y != "$CONTINUE" ]; then
  exit 0;
fi
STARTDIR=`pwd`
GITDIR=$STARTDIR
GITDIRVALID=0

while [ $GITDIR != / -a $GITDIRVALID -eq 0 ]; do
  if [ -d "$GITDIR/.git" ]; then
    GITDIRVALID=1
  else
    GITDIR=`readlink -f ${GITDIR}/..`
  fi
done

if [ $GITDIRVALID -eq 1 ]; then
  NOWDATE=`date +%Y%m%d%H%M`
  NAME=`basename \`pwd\``
  NAME=$NAME-${NOWDATE}.tar.gz
  git status --porcelain . | \
    awk '{
      if (NF==2) {
         print "'$GITDIR/'"$2
      } else if ($1="RM") {
         print "'$GITDIR/'"$4
      } else {
         print "Did not process -> " $0 > "/dev/stderr"
      }
     }' | \
  tar -cvzf "$GITDIR/$NAME" --exclude="$GITDIR/$NAME"  -T -
  echo
  echo $GITDIR/$NAME complete.
else
  echo "Must be a git repository."
fi
