#!/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git

if [[ -z $1 ]]; then
   echo No source directory. eg daren@192.168.1.4:/opt/film
   exit
fi

if [[ ! -e ./files ]]; then
  echo \'files\' containing a list of files for transfer does not exist.
  exit
fi

rsync -abHr --progress --no-implied-dirs --files-from=./files ${1} .

#files example:
#/opt/files/file.txt
#././file.txt

