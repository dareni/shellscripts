#!/bin/sh
if [ $# -eq 0 ]; then
    echo FreeBSD upgrade obsolete file check.
    echo 1. Create mtree file: obsolete_files.sh base_root_path
    echo 2. Run the check: obsolete_files.sh base.mtree_file base_root_path
elif [ $# -eq 1 ]; then
   mtree -c -k nochange -p $1 > mtree.out
elif [ $# -eq 2 ]; then
    RELEASE=`uname -r`
	mtree -f $1 -p $2 | grep extra \
        | grep -v "^boot/firmware" \
        | grep -v "^boot/kernel" \
        | grep -v "^boot/modules" \
        | grep -v "^boot/zfs" \
        | grep -v "^dev" \
        | grep -v "^etc/X11" \
        | grep -v "^home" \
        | grep -v "^media" \
        | grep -v "^mnt" \
        | grep -v "^proc" \
        | grep -v "^tmp" \
        | grep -v "^usr/compat" \
        | grep -v "^usr/games" \
        | grep -v "^usr/home" \
        | grep -v "^usr/local" \
        | grep -v "^usr/ports" \
        | grep -v "^usr/obj" \
        | grep -v "^usr/obj" \
        | grep -v "^var"
fi;

