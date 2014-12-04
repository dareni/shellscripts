VMNAME=beastie
#export VMNAME=s1
export BASEFOLDER=/vm/vbox
# vboxmanage list ostypes
OSTYPE=FreeBSD_64
#export OSTYPE=Ubuntu_64
vboxmanage createvm --name "$VMNAME" --basefolder "$BASEFOLDER" --ostype $OSTYPE --register
vboxmanage modifyvm "$VMNAME" --nictype1 82540EM --nic1 bridged --bridgeadapter1 eth0 --cableconnected1 on 
vboxmanage modifyvm "$VMNAME" --firmware bios --chipset piix3 --memory 256
vboxmanage modifyvm "$VMNAME" --boot1 dvd --boot2 disk --audio none --usb off --snapshotfolder default
#vboxmanage modifyvm $VMNAME --teleporter on --teleporterport 9999 --teleporteraddress 192.168.100.100

#Create dvd
vboxmanage storagectl "$VMNAME" --name ide --add ide --controller PIIX4 --bootable on
vboxmanage storageattach "$VMNAME" --storagectl ide --port 0 --device 0 --type dvddrive --medium emptydrive

#Create hd use sata - for best freebsd support.
#vboxmanage storagectl "$VMNAME" --name scsi --add scsi --controller LSILogic --bootable on --hostiocache on
vboxmanage storagectl "$VMNAME" --name sata --add sata  --bootable on --hostiocache on
export ROOTFILE="$BASEFOLDER/$VMNAME/${VMNAME}_root.vdi"
vboxmanage createhd --filename "$ROOTFILE" --format VDI --size 2048 --variant Standard
vboxmanage storageattach "$VMNAME" --storagectl sata --port 0 --device 0 --type hdd --medium "$ROOTFILE"

#Separate swap disk
SWAPFILE="$BASEFOLDER/$VMNAME/${VMNAME}_swap.vdi"
vboxmanage createhd --filename "$SWAPFILE" --format VDI --size 512 --variant Fixed
vboxmanage  storageattach "$VMNAME" --storagectl scsi --port 1 --device 0 --type hdd --medium "$SWAPFILE"

#vboxmanage unregistervm fbsd --delete
#vboxmanage startvm $VMNAME
#vboxmanage clonevm s1 --mode all --name s2 --basefolder "$BASEFOLDER" --register
#vboxmanage modifyhd /vm/disk1.vdi --resizebyte 1073741824

