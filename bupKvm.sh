#!/bin/env sh
#
# eg cephalox
VM_NAME="$1"
# eg ewan@ewan
VM_DEST_HOST=$2
# eg /opt/kvm/cephalox
VM_DEST_DIR=$3


if [ -z "$VM_DEST_DIR" ]; then
  echo
  echo " bupKvm.sh <vm name> <destination host> <destination directory>"
  echo
  echo "   where:"
  echo "   <vm name> is the host name from virsh list."
  echo "   <destination host> the ssh connect string ie user@host."
  echo "   <destination directory> the absolute path ie /opt/kvm/vm-host-name"
  echo
  exit -1
fi


if [ 1 -eq `virsh list --name |grep -c $VM_NAME` ]; then
  echo vm $VM_NAME is running and must be down for backup.
  return 1
fi

TMP_CONFIG=config.xml
TMP_NET=net-config.xml


if [ -e $TMP_CONFIG ]; then
  echo file exists $TMP_CONFIG
  exit -1
fi
if [ -e $TMP_NET ]; then
  echo file exists $TMP_NET
  exit -1
fi
DEST_USER=`echo $VM_DEST_HOST | cut -f1 -d@`

if [ -z "$DEST_USER" ]; then
  echo user does not exist in destination: $VM_DEST_HOST
fi

read -p "Backup $VM_NAME to $VM_DEST_HOST:$VM_DEST_DIR ctrl-c to exit." DUMMY

ssh $VM_DEST_HOST "mkdir -p $VM_DEST_DIR"
cat <<HEREDOC | ssh $VM_DEST_HOST "cat > $VM_DEST_DIR/notes.txt"
KVM notes
---------
apt-get install --no-install-recommends qemu-system libvirt-clients \
libvirt-daemon-system virtinst libosinfo-bin libguestfs-tools bridge-utils

Note: virt-ssbd does not exist for some physical host CPUs.

sudo adduser $DEST_USER libvirt
# setup network bridge permissions for qemu
sudo mkdir -p /etc/qemu
echo "allow all" | sudo tee /etc/qemu/${DEST_USER}.conf
echo "include /etc/qemu/${DEST_USER}.conf" | sudo tee --append /etc/qemu/bridge.conf
sudo chown root:${DEST_USER} /etc/qemu/${DEST_USER}.conf
sudo chmod 640 /etc/qemu/${DEST_USER}.conf

# osinfo update notes
sudo apt install osinfo-db-tools
wget https://releases.pagure.org/libosinfo/osinfo-db-20240523.tar.xz
sudo osinfo-db-import --local osinfo-db-20240523.tar.xz

#create a vm
virsh define ${TMP_CONFIG}
#create the default network
virsh net-define ${TMP_NET}
# The opposite to define is undefine.
# Force host shutdown.
virsh destroy ${VM_NAME}
#open the console for the vm (ctrl-shift-]) to end the session.
virsho console ${VM_NAME}

#Connection may be set by env ie VIRSH_DEFAULT_CONNECT_URI=qemu:///system
#Default is session, the user environment vs the system environment.
virsh --connect qemu:///<system or session>

HEREDOC

CONFIG=`virsh dumpxml $VM_NAME |tee $TMP_CONFIG`
FILES=`echo $CONFIG | xmllint -xpath '//domain/devices/disk/source/@file' -`
for FILE_ATTRIB in $FILES;
do
  FILENAME=`echo $FILE_ATTRIB | cut -f 2 -d "=" | tr -d \"`
  echo scp $FILENAME $VM_DEST_HOST:$VM_DEST_DIR
  #copy disk image file
  scp $FILENAME $VM_DEST_HOST:$VM_DEST_DIR
  FILE_PATH=`echo ${FILENAME%/*}`
  FILE=`echo ${FILENAME##*/}`
  #update the config file with the destination file paths.
  sed -e "s^"$FILE_PATH"^"$VM_DEST_DIR"^" $TMP_CONFIG > ${TMP_CONFIG}_tmp
  mv ${TMP_CONFIG}_tmp ${TMP_CONFIG}
done
scp $TMP_CONFIG $VM_DEST_HOST:$VM_DEST_DIR
rm $TMP_CONFIG

virsh net-dumpxml default > $TMP_NET
scp $TMP_NET $VM_DEST_HOST:$VM_DEST_DIR
rm $TMP_NET

echo $VM_NAME backup to $VM_DEST_HOST:$VM_DEST_DIR complete.

