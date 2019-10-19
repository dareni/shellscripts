#!/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git


if [[  $1 == '-h' ]]; then
   echo crypt.sh ./file.crypt 

fi

if [[ -z $1 ]]; then
  sudo umount /media
  sudo cryptsetup close blah
  sudo losetup -D
else 
  FILENAME=$1
  sudo losetup /dev/loop0 $FILENAME
  sudo cryptsetup open /dev/loop0 blah --type plain -c aes
  sudo mount /dev/mapper/blah /media
fi


