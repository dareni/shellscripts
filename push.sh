#!/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git

if [[ -z $1 ]]; then
   echo No target. eg daren@192.168.1.4:/opt/film
   exit
fi

rsync -abHr --progress --no-implied-dirs --files-from=./files \ -e ssh . ${1}

#files example:
#/home/daren/NetBeansProjects/svn-ozone3-mitchellcorp/ozone3-mitchellcorp/o3deploy/target/./o3deploy.war

