#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
echo "gitTarBup.sh: \n
Copy each modified file into a tar.
"
read -p "Continue (y/n): " CONTINUE

if [ y != "$CONTINUE" -a Y != "$CONTINUE" ]; then
  exit 0;
fi
if [ -d ".git" ]; then
NOWDATE=`date +%Y%m%d%H%M`
NAME=`basename \`pwd\``
NAME=$NAME-${NOWDATE}.tar.gz
  git status --porcelain |awk '{print $2}' | tar -cvzf $NAME --exclude=$NAME -T -
else
  echo "Must be a git repository."
fi
