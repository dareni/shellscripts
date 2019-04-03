#!/bin/sh
# Find all rcs files with outstanding commits.

read -p "Run updatedb? y/[N]" UPDATE
if [ "y" = "$UPDATE" ]; then
  sudo updatedb
fi

locate RCS | grep ",v" | awk '{
    segNum=split($0,segs,"/")
    rcsfile=segs[segNum]
    rcsfile=substr(rcsfile,1,length(rcsfile)-2)
    filePathPOS=index($0,"RCS")
    filePath=substr($0,1,filePathPOS-1)
    absFile=filePath""rcsfile
    print  $0" "absFile
}' |xargs -n 2 rcsdiff 2>&1 |vim -R -
