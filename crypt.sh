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
   echo crypt.sh [./file.crypt] [mountNo [rw]]
else
  #Store mount No option
  if [[ ${#1} -eq 1 ]]; then
    MNT=$1
  elif [[ ${#2} -eq 1 ]]; then
    MNT=$2
  else
    MNT=1
  fi
  if [[ ${#1} -gt 1 ]]; then
    FILENAME=$1
  else
    FILENAME=""
  fi

  if [[ "${3}" = "rw" ]]; then
    OPT=""
  else
    OPT="-o ro"
  fi

fi

if [[ -z "$FILENAME" ]]; then
  sudo umount /media/media${MNT}
  sudo cryptsetup close blah${MNT}
  sudo losetup -D
else
  sudo losetup /dev/loop${MNT} $FILENAME
  sudo cryptsetup open /dev/loop${MNT} blah${MNT} --type plain -c aes
  sudo mount $OPT /dev/mapper/blah${MNT} /media/media${MNT}
fi


