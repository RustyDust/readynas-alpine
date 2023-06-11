#!/bin/sh

modprobe btrfs
modprobe raid0
modprobe raid1
modprobe raid5
modprobe vfat

# -- assemble raid arrays
mdadm --assemble --scan 2>&1 /dev/null

# - we now should have at least md0, md1 and md127
# - 
# sru_230611: doesn't work that way because Alpine
#     uses a different numbering scheme than Debian
# -
# ISRN=1
# MDS="0 1 127"
# for MDDEV in ${MDS}; do
#   if test ! -b /dev/md${MDDEV}; then
#     ISRN=0
#   fi
# done
# 
# if test ${ISRN} -ne 1; then
#   echo "This doesn't look like a ReadyNAS -> aborting!!"
#   exit 111
# fi

# -- check for BTRFS file systems
# - Step1: get list of file systems
BTRFSFS=`btrfs filesystem show | awk -F\' '/^Label:/ { print $2 }'`

# - Step2: split in root and data volumes
#   ROOTFS is the mount for the old ReadyNAS OS (/root/rnos_bak)
#   DATAFS is a list for mounted data volumes under /
ROOTFS=
DATAFS=
for FS in ${BTRFSFS}; do
  if test ! -z `echo ${FS} | grep root`; then
    ROOTFS=${FS}
  else
    DATAFS="${DATAFS}${FS} "
  fi
done

if test -z "${ROOTFS}"; then
  echo "No ReadyNAS OS root partition foubnd -> aborting!!"
  exit 111
fi

if test -z "${DATAFS}"; then
  echo "No data volumes found -> you sure this is a ReadyNAS?"
  exit 111
fi

echo ${ROOTFS}
echo ${DATAFS}

# !!!
# If we have more than one data partition, on which one do we place the
# OS stuff? For now we just use the first one we find that has a '.apps'
# subvolume and thus has to be the first one created when installing the
# ReadyNAS for the first time.
# !!!
OSVOL=
APPVOL=
ADDMNT=

# create temporary mount dir for our checks
mkdir -p /tmp_btrfs
for DS in ${DATAFS}; do
  # - get the BTRFS subvolumes
  mount LABEL=${DS} /tmp_btrfs
  TSTVOL=`btrfs subvolume list /tmp_btrfs | grep \.apps`
  # if we have a .apps subvol, this will be our OSVOL
  if test ! -z "${TSTVOL}"; then
    # remember the OS volume
    OSVOL=${DS}
    APPVOL=${DS}
    # mount it to /mnt for setup-disks
    mount LABEL=${DS} /mnt
  else
    # collect the non-OS volumes here
    ADDMNT="${ADDMNT}${DS}"
  fi
  umount /tmp_btrfs
done
rm -rf /tmp_btrfs

# by now we should have an OS volume
if test -z "${OSVOL}"; then
  echo "Unable to find suitable volume for OS -> aborting"
  exit 111
fi

# and it should be mounted
TSTMNT=`mount | grep /mnt`
if test -z "$TSTMNT"; then
  echo "No root volume mounted -> can't continue :-("
  exit 111
fi

# mount app volume
if test ! -d /mnt/apps; then
  mkdir /mnt/apps
fi
mount LABEL=${OSVOL} -o subvol=.apps /mnt/apps

# mount additional volumes if any
if test ! -z "${ADDMNT}"; then
  for ADD in ${ADDMNT}; do
    SUBPATH=`echo ${ADD} | awk -F: '{ print $2}'`
    mkdir -p /mnt/${SUBPATH}
    mount LABEL=${ADD} /mnt/${SUBPATH}
  done
fi

# mount backup of old ReadyNAS OS
mkdir -p /mnt/rnos_bak
mount LABEL=${ROOTFS} /mnt/rnos_bak

echo "root:${ROOTFS}"
echo "os:  ${OSVOL}"
echo "app: ${APPVOL}"
echo "oth: ${ADDMNT}"

# -- find the original ReadyNAS USB boot drive
USBDISK=`lsblk -io KNAME,MODEL | grep "USB DISK" | awk '{ print $1 }'`
if test -z "${USBDISK}"; then
  echo "No USB boot disk found -> you sure this is a ReadyNAS?"
  exit 111
fi

# mount the boot disk so we can use it
mkdir -p /mnt/boot
mount /dev/${USBDISK}1 /mnt/boot

# create a backup in /etc/readynas_boot
mkdir -p /etc/readynas_boot
cd /mnt/boot
tar cf - . | tar -C /etc/readynas_boot -xf -
cd - 2>&1 /dev/null
# make a backup copy of the original MBR
dd if=/dev/${USBDISK} of=/etc/readynas_boot/readynas.mbr bs=446 count=1

# better safe than sorry: copy stuff from rnos_bak to /etc
# if we don't need to, we can remove that later.
mkdir -p /etc/readynas/etc
cd /mnt/rnos_bak/etc
tar cf - frontview | tar -C /etc/readynas/etc -xf -
cd - 2>&1 /dev/null
cd /mnt/rnos_bak
tar cf - frontview | tar -C /etc/readynas -xf -
cd - 2>&1 /dev/null
