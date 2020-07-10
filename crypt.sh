#!/bin/bash
# Maintained at: git@github.com:dareni/shellscripts.git

# To create a file.
# dd if=/dev/zero of=/opt/dev/test.dat bs=1M count=600
# sudo losetup /dev/loop0 /opt/dev/test.dat
# sudo cryptsetup open /dev/loop0 blah --type plain -c aes
# mkfs.ext4 /dev/mapper/blah

# To extend a file.
# dd oflag=append conv=notrunc if=/dev/zero of=./test.dat bs=1M count=50
# crypt.sh ./test.dat
# sudo cryptsetup resize blah
# sudo resize2fs /dev/mapper/blah


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


