# ========================================================
#
# To start off, boot from alpine extended (so you get ZFS)
#
# ========================================================

# This would be the preflight data one has to input:
cat - >/root/answers <<-__EOF__
KEYMAPOPTS="de de-nodeadkeys"
# This would be your hostname:
HOSTNAMEOPTS="-n rnxpine"
# Domain name + DNS server:
DNSOPTS="-d rnxtras.com 1.1.1.1"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
    hostname rnxpine

auto eth1
iface eth0 inet dhcp
    hostname rnxpine
"

TIMEZONEOPTS="-z Europe/Berlin"
PROXYOPTS=none
APKREPOSOPTS="-1"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
# Leave the following as is (see below why):
DISKOPTS="-z --please-dont-do-anything"
__EOF__

# --------------------------------------------------------
#
# FIXME: DNSOPTS (domainname) aren't honored when using DHCP.
# Untested workaround is probably running `setup-dns -d wejn.org 1.1.1.1`
# before running `setup-alpine`.
#
# Run basic setup, which will fail at disk setup time due to garbled $DISKOPTS
setup-alpine -e -f /root/answers

# --------------------------------------------------------
# Change root's password (non-interactive alternative to "passwd"
# You can gen the hash via: `mkpasswd -m SHA-512 -P 3 3<<<mypassword`
sed -i 's@^root::@root:$6$somesalthere.$[--thiswouldbetherootpwhash--]:@' /etc/shadow

# Setup ssh access for a given set of ssh keys
mkdir -m 0700 /root/.ssh
cat - >/root/.ssh/authorized_keys <<-__EOF__
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIItGb5Up1jVrePp4v9lffz5xzw4HOXQFS6QumtATZYbA wejn@sigh
__EOF__

# Tweak /etc/issue, clear /etc/motd
cat - >/etc/issue <<-__EOF__

Terminal ready on \l.

$(ssh-keygen -l -v -f /etc/ssh/ssh_host_ecdsa_key.pub)

__EOF__
> /etc/motd

# --------------------------------------------------------
# Enable community repository
sed -i -r 's,#(.*/v.*/community),\1,' /etc/apk/repositories
apk update

# Add required packages
# apk add zfs sfdisk e2fsprogs mdadm cryptsetup xkcdpass gnupg e2fsprogs-extra openssl sbsigntool
apk add btrfs-tools sfdisk nano mc e2fsprogs mdadm cryptsetup xkcdpass gnupg e2fsprogs-extra openssl sbsigntool

# --------------------------------------------------------
# Partition disks
#
# The partition layout:
# p1 - ESP, EFI System Partition (on swraid)
# p2 - /boot, LUKS-on-swraid
# p3 - swap, LUKS-on-swraid
# p4 - zfs, ZFS encrypted pool
#
for i in /dev/nvme?n?p?; do
    dd if=/dev/zero of=$i bs=4k count=1k
    mdadm --zero-superblock $i
done
for i in /dev/nvme0n1 /dev/nvme1n1; do
  dd if=/dev/zero of=$i bs=4k count=1k
  cat - <<-__EOF__ | sfdisk --quiet --label gpt $i
${i}p1: start=1M,size=100M,bootable,type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
${i}p2: size=400M,type=A19D880F-05FC-4D3B-A006-743F0F84911E
${i}p3: size=8G,type=A19D880F-05FC-4D3B-A006-743F0F84911E
${i}p4: type=6A898CC3-1DD2-11B2-99A6-080020736631
__EOF__
done

# --------------------------------------------------------
# Add btrfs to kernel modules
modprobe btrfs
echo btrfs >> /etc/modules-load.d/btrfs.conf

# --------------------------------------------------------
# Spin up the raid on all partitions
modprobe raid1
echo raid1 >> /etc/modules-load.d/raid1.conf
modprobe raid5
echo raid1 >> /etc/modules-load.d/raid5.conf

mdadm --create --level=1 --metadata=1.0 --raid-devices=2 /dev/md0 /dev/nvme0n1p1 /dev/nvme1n1p1
mdadm --create --level=1 --metadata=1.0 --raid-devices=2 /dev/md1 /dev/nvme0n1p2 /dev/nvme1n1p2
mdadm --create --level=1 --metadata=1.0 --raid-devices=2 /dev/md2 /dev/nvme0n1p3 /dev/nvme1n1p3
mdadm --detail --scan > /etc/mdadm.conf

rc-update add mdadm-raid
rc-update add mdadm boot
rc-update add mdadm-raid boot

# --------------------------------------------------------
# Setup the encrypted swap, with keyfile in /etc/fstab.swap_keyfile
echo -n $(xkcdpass -n 25) > /etc/fstab.swap_keyfile
chmod go= /etc/fstab.swap_keyfile
cryptsetup luksFormat -q -d /etc/fstab.swap_keyfile /dev/md2
cryptsetup luksOpen -d /etc/fstab.swap_keyfile /dev/md2 encswap
mkswap /dev/mapper/encswap
swapon /dev/mapper/encswap

# --------------------------------------------------------
# Setup the ZFS pool, with key in /etc/fstab.zfs_keyfile
modprobe zfs
echo -n $(xkcdpass -n 25) > /etc/fstab.zfs_keyfile
chmod go= /etc/fstab.zfs_keyfile
zpool create -f \
  -o ashift=12 -O acltype=posixacl -O canmount=off -O compression=lz4 \
  -O dnodesize=auto -O normalization=formD -O relatime=on -O xattr=sa \
  -O encryption=aes-256-gcm \
  -O keyformat=passphrase -O keylocation=file:///etc/fstab.zfs_keyfile \
  -O mountpoint=/ -R /mnt \
  nvmetank mirror /dev/nvme0n1p4 /dev/nvme1n1p4
# Change keylocation to prompt (for now):
zfs set keylocation=prompt nvmetank
# to change ZFS key:
# zfs change-key -l -o keylocation=prompt -o keyformat=passphrase nvmetank
# emergency load:
# zfs load-key -L prompt nvmetank

# Setup the mountpoints:
zfs create -o mountpoint=none -o canmount=off nvmetank/ROOT
zfs create -o mountpoint=legacy -o canmount=off nvmetank/ROOT/alpine
mount -t zfs nvmetank/ROOT/alpine /mnt/

# Make sure the ZFS boots :)
rc-update add zfs-import sysinit
rc-update add zfs-mount sysinit

# --------------------------------------------------------
# Format + mount the ESP as /efi (now that we have root mounted as /mnt)
mkdir /mnt/efi
mkfs.vfat -F32 -n efi /dev/md0
mount -t vfat /dev/md0 /mnt/efi/

# --------------------------------------------------------
# Setup the /boot partition with /etc/fstab.boot_keyfile and fixed password
mkdir /mnt/boot
echo -n $(xkcdpass -n 25) > /etc/fstab.boot_keyfile
chmod go= /etc/fstab.boot_keyfile
cryptsetup luksFormat -q --type luks1 -d /etc/fstab.boot_keyfile /dev/md1
echo -n i-am-begging-to-get-pwned-here > /root/boot.ephemeral_keyfile
# FIXME: You want to change this^^ static password. :-) That's the one you
# will need to enter upon boot, tho. So choose wisely.
cryptsetup luksAddKey /dev/md1 -d /etc/fstab.boot_keyfile /root/boot.ephemeral_keyfile
cryptsetup luksOpen -d /etc/fstab.boot_keyfile /dev/md1 encboot
mkfs.ext4 /dev/mapper/encboot
mount -t ext4 /dev/mapper/encboot /mnt/boot

# --------------------------------------------------------
# Finish the alpine setup (install the system, sans reasonable bootloader)
setup-disk /mnt/


# --------------------------------------------------------
#
# Up to this point package installations and tweaks to
# /etc were transferred to the new system.
#
# But from this point on, no changes in / are transferred.
# So tread carefully.


# --------------------------------------------------------
# Make passwordless zfs mount (it's safe because /boot is encrypted)
chroot /mnt ln -s /etc/fstab.zfs_keyfile /crypto_keyfile.bin
zfs set keylocation=file:///crypto_keyfile.bin nvmetank

# --------------------------------------------------------
# Tweak mkinitfs' features to enable bunch of stuff we need (and setup-disk didn't detect)
sed -i 's/zfs/nvme raid cryptsetup cryptkey ext4 zfs/' /mnt/etc/mkinitfs/mkinitfs.conf
mkinitfs -c /mnt/etc/mkinitfs/mkinitfs.conf -b /mnt/ $(ls /mnt/lib/modules/)

# --------------------------------------------------------
# Make sure encrypted swap and /boot are mounted
cat - >>/mnt/etc/conf.d/dmcrypt <<-__EOF__

target='encswap'
source='/dev/md2'
key='/etc/fstab.swap_keyfile'

target='encboot'
source='/dev/md1'
key='/etc/fstab.boot_keyfile'

__EOF__
cat - >>/mnt/etc/fstab <<-__EOF__
/dev/mapper/encswap none swap sw,defaults 0 0
__EOF__
sed -i 's,^UUID=.*/boot,/dev/mapper/encboot /boot,' /mnt/etc/fstab

chroot /mnt rc-update add dmcrypt boot
chroot /mnt rc-update add swap boot

# --------------------------------------------------------
# Set up grub bootloader
mount -t proc /proc /mnt/proc
mount --rbind /dev /mnt/dev
mount --make-rslave /mnt/dev
mount --rbind /sys /mnt/sys
chroot /mnt apk add grub grub-efi efibootmgr
chroot /mnt apk del syslinux
chattr -i /mnt/boot/ldlinux*
rm -f /mnt/boot/*.c32 /mnt/boot/ldlinux* /mnt/boot/extlinux.conf /mnt/boot/boot
cat - >/mnt/etc/default/grub <<-__EOF__
GRUB_DISTRIBUTOR="Alpine"
GRUB_TIMEOUT=2
GRUB_DISABLE_SUBMENU=y
GRUB_DISABLE_RECOVERY=true
GRUB_PRELOAD_MODULES="luks cryptodisk part_gpt lvm"
GRUB_ENABLE_CRYPTODISK=y
GRUB_DISABLE_LINUX_PARTUUID=true
GRUB_DISABLE_LINUX_UUID=true
# Update 2022-03-08: something changed in grub-mkconfig, because
# "stat -f -c %T /" started returning "zfs" instead of "unknown", which in turn
# borked the linux configuration, because /etc/grub.d/10_linux started messing
# up the LINUX_ROOT_DEVICE because determination of the rpool failed. This fixes
# it (but "diff -u /boot/grub/grub.cfg*" when upgrading is still advised):
GRUB_DEVICE=ZFS=nvmetank/ROOT/alpine
GRUB_FS=noneofyourbusiness
# And this fixes the sudden duplication of cmdline flags (why the hell?!)
GRUB_CMDLINE_LINUX_DEFAULT=""
__EOF__
sed -i 's/^modules=.*/modules=nvme,zfs/' /mnt/etc/update-extlinux.conf
chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
chroot /mnt grub-install --target=x86_64-efi --efi-directory=/efi
# The grub install partially fails (the call to efibootmgr does) because of raid.
# Because grub tries to give two devices to efibootmgr (who doesn't like that).
# 
# It's fine, tho, we can use the fallback /EFI/boot/bootx64.efi path within ESP.
mkdir /mnt/efi/EFI/boot
# Update 2021-09-26: Turn off "secureboot" in grub, see:
# https://wejn.org/2021/09/fixing-grub-verification-requested-nobody-cares/
sed -i 's/SecureBoot/SecureB00t/' /mnt/efi/EFI/alpine/grubx64.efi
#
mv /mnt/efi/EFI/alpine/grubx64.efi /mnt/efi/EFI/boot/bootx64.efi
rmdir /mnt/efi/EFI/alpine
# Oh, and grub, f-off with grubenv, will ya? It's on RAID anyway.
rm /mnt/boot/grub/grubenv

# --------------------------------------------------------
# Time to setup the glorious Secure boot
mkdir -m 0700 /mnt/boot/secureboot
# Generate the cert
openssl req -new -x509 -newkey rsa:2048 -keyout /mnt/boot/secureboot/sb.key \
    -out /mnt/boot/secureboot/sb.crt -nodes -days 36500 -subj "/CN=Wejn SB CA/"
openssl x509 -in /mnt/boot/secureboot/sb.crt -out /mnt/boot/secureboot/sb.cer -outform DER
# Sign grub. This is, btw, the command you'll be re-running if you update grub
# binary sometime later (along with the "mv" a few lines above, I guess).
sbsign --key /mnt/boot/secureboot/sb.key --cert /mnt/boot/secureboot/sb.crt \
    /mnt/efi/EFI/boot/bootx64.efi
mv /mnt/efi/EFI/boot/bootx64.efi.signed /mnt/efi/EFI/boot/bootx64.efi
# Copy the "sb.cer" so it can be added to bios. I have it as all of: PK, KEK, db.
cp /mnt/boot/secureboot/sb.cer /mnt/efi/sb.cer

# Carry over root's authorized_keys
cp -a /root/.ssh/ /mnt/root/

# --------------------------------------------------------
#
# This section is completely optional, but recommended:
#
# Make this system recoverable by gpg-encrypting keys
# and certs using GPG to the ESP.
#
# That way if something fails, at least you have a way
# to run recovery.
#
cat - > /mnt/root/wejn.asc <<-__EOF__
-----BEGIN PGP PUBLIC KEY BLOCK-----
[...snip...]
-----END PGP PUBLIC KEY BLOCK-----
__EOF__
chroot /mnt gpg --import /root/wejn.asc
echo 'CC15927C8B00192715EAE5C08911469B691A16D4:6:' | chroot /mnt gpg --import-ownertrust
cat - >/mnt/root/save-keys <<-'__EOF__'
for i in /etc/fs*key* /boot/secureboot/sb.*; do
  cat $i | gpg --encrypt -r box@ --armor > /efi/$(basename $i).asc
done
__EOF__
chroot /mnt ash /root/save-keys
chroot /mnt ash -c 'ls -l /efi/*asc'

# --------------------------------------------------------
# NOT OPTIONAL -- cleanup :-)
umount -l /mnt/dev
umount -l /mnt/proc
umount -l /mnt/sys
