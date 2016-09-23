#!/bin/sh
# Maintained at: git@github.com:dareni/shellscripts.git
LOCAL_KEY=~/.ssh/id_rsa.pub

if [ -z "$1" ]; then
    echo "Usage: ./doKeyCopy.sh username@host.domain"
else
    if [ ! -e $LOCAL_KEY ]; then
        echo Local key file $LOCAL_KEY does not exist.
        exit 1;
    fi;
    cat $LOCAL_KEY | ssh $1 'dd >> ~/.ssh/authorized_keys; /bin/sh -c "if [ ! -d ~/.ssh ]; then mkdir ~/.ssh; chmod 700 ~/.ssh; echo Just created ~/.ssh please run again; fi"'
fi
