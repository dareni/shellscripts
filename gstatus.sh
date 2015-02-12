#!/bin/sh
#Print the status of all git repo subdirectories.

find . -name ".git" -exec echo \; -execdir pwd \; -execdir  git status \; 
