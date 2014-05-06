#!/bin/sh
# 20110801 dki Add comment for swap creation.
# 20110825 dki Add notes for transfer of a zpool.

#zpool transfer example
## zpool create ztmp ad4
## zfs snapshot zdata@ss1
## zfs snapshot zdata/bup@ss1
## zfs send -R zdata@ss1 |zfs receive -F -d ztmp

#transfer of zpool filesystem
## zfs snapshot zdata/up@ss1
## zfs send -R zdata/bup@ss1 | zfs receive -d ztmp

DISK1=ad0; export DISK1
DISTLOC='/mnt/8*'; export DISTLOC
HOSTNAME="zbeastie.localdomain"
IFCONFIG='ifconfig_em0="inet 192.168.1.97  netmask 255.255.255.0"'
#IFCONFIG='ifconfig_em0="DHCP"'

#Use dmesg to get the network device.
# For scp:
# run ifconfig em0 192.168.10.97
# mkdir /usr/bin; cp /dist/usr/bin/ssh /usr/bin

# Creating swap
# zfs create -V 2g zroot/swap
# swapon -a /dev/zvol/zroot/swap 
# fstab: /dev/zvol/zroot/swap none swap sw 0 0

if [ "$1" = "" ]; then
    echo
    echo "usage zfs.sh do_gpart | do_chroot | do_final"
    echo "start with do_gpart, this will destroy ${DISK1}"
    echo
    exit
fi


if [ "$1" = "do_gpart" ]; then
    echo  "doing gpart"
    echo
    echo "Hostname: $HOSTNAME"
    echo "ifconfig: $IFCONFIG"
    echo "Distribution location: $DISTLOC"
    echo -n ":NOTE: /dev/${DISK1} will be destroyed! continue \(y/N\):"
    read ANS
    echo

    if [ "$ANS" != "y" ]; then
        exit;
    fi

    gpart destroy -F $DISK1
    gpart create -s GPT $DISK1
    gpart add -b 34 -s 256 -t freebsd-boot $DISK1
    gpart add -b 290 -t freebsd-zfs $DISK1
#    gpart set -a active -i 1 $DISK1

    kldload /mnt2/boot/kernel/opensolaris.ko
    kldload /mnt2/boot/kernel/zfs.ko
    mkdir /boot/zfs
    zpool create zroot /dev/${DISK1}p2
    zpool set bootfs=zroot zroot
    ##To later mirror do eg #zpool attach zroot ad0p2 ad2p2

    zpool export zroot
    gpart bootcode -b /dist/boot/pmbr -p /dist/boot/gptzfsboot -i 1 $DISK1
    zpool import zroot

    zfs set checksum=fletcher4 zroot
    zfs create -o compression=on    -o exec=on      -o setuid=off   zroot/tmp
    chmod 1777 /zroot/tmp
    zfs create zroot/usr
    zfs create zroot/usr/home
    cd /zroot ; ln -s /usr/home home

    zfs create                                                      zroot/var
    zfs create -o compression=lzjb  -o exec=off     -o setuid=off   zroot/var/crash
    zfs create                      -o exec=off     -o setuid=off   zroot/var/db
    zfs create -o compression=lzjb  -o exec=on      -o setuid=off   zroot/var/db/pkg
    zfs create                      -o exec=off     -o setuid=off   zroot/var/empty
    zfs create -o compression=lzjb  -o exec=off     -o setuid=off   zroot/var/log
    zfs create -o compression=gzip  -o exec=off     -o setuid=off   zroot/var/mail
    zfs create                      -o exec=off     -o setuid=off   zroot/var/run
    zfs create -o compression=lzjb  -o exec=on      -o setuid=off   zroot/var/tmp
    chmod 1777 /zroot/var/tmp

    cd $DISTLOC
    export DESTDIR=/zroot
    for dir in base catpages dict manpages; \
        do (cd $dir ; ./install.sh) ; done
    cd kernels; ./install.sh generic
    rmdir /zroot/boot/kernel; mv /zroot/boot/GENERIC /zroot/boot/kernel

    zfs set readonly=on zroot/var/empty

    echo 'zfs_enable="YES"' > /zroot/etc/rc.conf
    echo 'sshd_enable="YES"' >> /zroot/etc/rc.conf
    echo "hostname=\"$HOSTNAME\"" >> /zroot/etc/rc.conf
    echo $IFCONFIG >> /zroot/etc/rc.conf
    echo 'zfs_load="YES"' > /zroot/boot/loader.conf
    echo 'vfs.root.mountfrom="zfs:zroot"' >> /zroot/boot/loader.conf


    cp /zfs.sh /zroot
    cd /
    echo "next:" 
    echo "1. chroot /zroot"
    echo "2. /zfs.sh do_chroot"
fi

if [ "$1" = "do_chroot" ]; then
    echo  "doing chroot"
    if [ -d /zroot ]; then
        echo "do chroot ie"
        echo "chroot /zroot"
        exit 
    fi;

    passwd
    tzsetup
    cd /etc/mail
    make aliases
    echo "create users pw useradd .name. -G wheel -m"
    echo "next:"
    echo "1. exit the chroot."
    echo "2. export LD_LIBRARY_PATH=/mnt2/lib"
    echo "3. run /zfs.sh do_final"
fi

if [ "$1" = "do_final" ]; then
    echo  "do final"
    cp /boot/zfs/zpool.cache /zroot/boot/zfs/zpool.cache
    cat << EOF > /zroot/etc/fstab
## Device                       Mountpoint              FStype  Options         Dump    Pass#
# /dev/ad0s3b                    none                    swap    sw              0       0
EOF
    cd /
    zfs unmount -a
    zfs set mountpoint=legacy zroot
    zfs set mountpoint=/tmp zroot/tmp
    zfs set mountpoint=/usr zroot/usr
    zfs set mountpoint=/var zroot/var
fi

