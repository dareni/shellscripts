#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
echo "gitpatch.sh: \n
1) stash all changes in the current workspace including new and deleted files, \n\
2) create a patch of the stashed changes.
"
read -p "Continue (y/n): " CONTINUE

if [ y != "$CONTINUE" -a Y != "$CONTINUE" ]; then
  exit 0;
fi
if [ -d ".git" ]; then
  git add -A
  git stash save "Patch"
  DATE=`date +%y%m%d`
  git stash show -p > git.patch.$DATE
  echo "Now use: git apply git.patch"
else
  echo "Must be a git repository."
fi
