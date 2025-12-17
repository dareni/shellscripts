#!/bin/env bash
# Pull the public ip address from the firewall.
# Maintained at: git@github.com:dareni/shellscripts.git

if [[ -z "$2" ]]; then
  wget 192.168.1.253 -O - | grep 'WAN IP' | awk -F'<strong>|</strong></font>' '{print $2}'
  exit
fi

NAME=$1
PASSWORD=$2

#Retrieve the post action url.
URL=$(wget 192.168.1.253 -O - | grep '<form' | awk '{print $3}' | sed 's/^........//' | sed 's/.$//')
#Post the username/password to access the status page containing the public ip.
wget -O - --post-data 'HngLoginUserName='${NAME}'&HngLoginPassword='${PASSWORD} 192.168.1.253${URL} |
  grep '^<div.*WAN IP' | sed 's/^.\{60\}//' | sed 's/..strong.*$//'
