#!/bin/sh
# 20110925 dki Create ufs.sh from zfs.sh

#bud disk usage
#/ 1G
#/usr/home/jail/usr/local 1G
#              /usr/packages mounted
#              /usr/ports    mounted
#/usr/local 1G
#/usr/ports .5G
#/usr/packages .5G
#/var .5
#swap 1G

#/ 1G
DISK1=ad4; export DISK1
#swap 1G
DISK2=ad6; export DISK2
#/usr 3G
DISK3=ad8; export DISK3
#/var .5G
DISK4=ad10; export DISK4

DISTLOC='/dist/8*'; export DISTLOC
HOSTNAME="dev.localdomain"
IFCONFIG='ifconfig_em0="inet 192.168.1.8  netmask 255.255.255.0"'
#IFCONFIG='ifconfig_em0="DHCP"'


#Use dmesg to get the network device.
# For scp:
# run ifconfig em0 192.168.1.97
# mkdir /usr/bin; cp /dist/usr/bin/ssh /usr/bin

# Creating swap
# zfs create -V 2g zroot/swap
# swapon -a /dev/zvol/zroot/swap 
# fstab: /dev/zvol/zroot/swap none swap sw 0 0

if [ "$1" = "" ]; then
    echo
    echo "usage ufs.sh do_gpart | do_chroot | do_final"
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

# 1G swap 1024*1024*1024/512    
    gpart create -s GPT $DISK1

    gpart add -b 34 -s 256 -t freebsd-boot $DISK1
    gpart add -b 290 -t freebsd-ufs $DISK1
    gpart bootcode -b /dist/boot/pmbr -p /dist/boot/gptboot -i 1 $DISK1
    #gpart set -a active -i 1 $DISK1

    newfs -nL root /dev/${DISK1}p2
    newfs -nUL usr /dev/$DISK3
    newfs -nUL var /dev/$DISK4

    mkdir /newroot 
    mount /dev/${DISK1}p2 /newroot
    mkdir /newroot/usr
    mkdir /newroot/var
    mount /dev/ufs/usr /newroot/usr
    mount /dev/ufs/var /newroot/var
   # mount /dev/${DISK1}p1 /root
    

    mkdir /newroot/var/tmp
    chmod 1777 /newroot/var/tmp
    cd /newroot 
    ln -s var/tmp tmp
    mkdir usr/home
    ln -s usr/home home

    cd $DISTLOC
    export DESTDIR=/newroot
    for dir in base catpages dict manpages; \
        do (cd $dir ; ./install.sh) ; done
    cd kernels; ./install.sh generic
    rmdir /newroot/boot/kernel; mv /newroot/boot/GENERIC /newroot/boot/kernel


    echo 'sshd_enable="YES"' >> /newroot/etc/rc.conf
    echo 'defaultrouter="192.168.1.254"' >> /newroot/etc/rc.conf
    echo "hostname=\"$HOSTNAME\"" >> /newroot/etc/rc.conf
    echo $IFCONFIG >> /newroot/etc/rc.conf


    cp /ufs.sh /newroot
    cd /
    echo "next:" 
    echo "1. chroot /newroot"
    echo "2. /ufs.sh do_chroot"
fi

if [ "$1" = "do_chroot" ]; then
    echo  "doing chroot"
    if [ -d /newroot ]; then
       echo You did not chroot!
       exit;
    fi

    passwd
    tzsetup
    cd /etc/mail
    make aliases
    echo "create users pw useradd .name. -G wheel -m"
    echo "next:"
    echo "1. exit the chroot."
    echo "2. export LD_LIBRARY_PATH=/mnt2/lib"
    echo "3. run /ufs.sh do_final"
fi

if [ "$1" = "do_final" ]; then
    echo  "do final"
    cat << EOF > /newroot/etc/fstab
## Device                       Mountpoint              FStype  Options         Dump    Pass#
# /dev/ad0s3b                    none                    swap    sw              0       0
/dev/ad4p2                      /                       ufs      rw 1 1
/dev/ufs/usr                    /usr                    ufs      rw 2 2
/dev/ufs/var                    /var                    ufs      rw 2 2
EOF
    cd /
fi

