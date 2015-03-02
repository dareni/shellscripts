#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
#Print the status of all git repo subdirectories.

find . -name ".git" -exec echo \; -execdir pwd \; -execdir  git status \; 
