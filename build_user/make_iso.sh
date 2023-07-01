#!/bin/sh

# Original script:  Michal Jirků, https://wejn.org/2022/04/alpinelinux-unattended-install/
# Adapted for ReadyNAS migration: Stefan Rubner <stefan@whocares.de>

# =========================================================
#
# IMPORTANT
# 
# This scripts exports the following environment variables that are later on used to 
# determine the setup of the ISO image:
#
# KEYMAP        sets the keyboard language for the installed version
# LASTRNCMD     determines whether to power off the system or stay in a shell
#               after the conversion is done
# MEBUILDROOT   the directory we're build in
# PROFILENAME   name of the profile that is bein built
# TMPDIR        location of temporary files for ISO creation
#
# =========================================================

# find our current dir
MEDIR=`pwd`
export MEBUILDROOT=${MEDIR}

# Create local RSA signing key (which is IMO useless in this case, but WTHDIK)
if test ! -f ~/.abuild/abuild.conf; then
  echo "No signing key found -> creating a new one"
  abuild-keygen -i -a
else
  . ~/.abuild/abuild.conf
  if [ -z "${PACKAGER_PRIVKEY}" ]; then
    echo "No signing key in ~/.abuild/abuild.conf -> crating a new one"
    abuild-keygen -i -a
  else
    if test ! -f ${PACKAGER_PRIVKEY}; then
      echo "Key from abuild.conf doesn't exist -> creating a new one"
      abuild-keygen -i -a
    fi
  fi
fi

# remove wireless-regdb 
sed -i -e 's/wireless-regdb//g' aports/scripts/mkimg.base.sh

# make the iso more chatty
sed -i -e 's/ quiet/ video=800x600@60/g' aports/scripts/mkimg.base.sh
sed -i -e 's/ quiet/ video=800x600@60/g' aports/scripts/mkimg.standard.sh

# enable serial console
if test ! -f aports/scripts/serial_console; then
  sed -i 's/\(esac\)/\t*)\n\t\t\tkernel_cmdline="console=tty0 console=ttyS0,115200"\n\t\t\t;;\n\t\1/' aports/scripts/mkimg.standard.sh
  touch aports/scripts/serial_console
fi

# Shallow clone aports (to get the scripts)
if test -d aports/.git; then
  cd aports
  git pull
  cd -
else 
  rm -rf aports
  git clone --depth 1 https://gitlab.alpinelinux.org/alpine/aports.git
fi

# Find our active branch -> will be the ISO's tag
GITBRANCH=`git branch | grep \* | awk '{ print $2 }'`
if test "${GITBRANCH}" != "main"; then
  GITREV=`git rev-parse --short=6 HEAD`
  GITREV="dev_${GITREV}"
  # don't poweroff the dev versions
  export LASTRNCMD=""
else
  # use the latest tag instead of the commit hash
  GITREV=`git tag | tail -n1 | tr '.' '_'`
  export LASTRNCMD="poweroff"
fi 

# remove old scripts 
rm -f ${MEDIR}/aports/scripts/*rnos*

# Create output dir
mkdir -p ${MEDIR}/iso
rm -rf ${MEDIR}/iso/*

export PROFILENAME="rnos6"

# Basic profile data -- inherits from standard, but the main thing to make
# it work is the `apkovl=`. This is the script that configures most of the
# iso creation and allows you to control precooked packages and stuff.

APKS="avahi btrfs-progs coreutils cups cups-filters curl dosfstools
      gawk hplip mc mdadm nano net-snmp nfs-utils ntfs-3g proftpd
      rsync samba sane sane-backends shadow util-linux vim"

sed -e "s/%PROILENAME%/${PROFILENAME}/g;s/%APKS%/${APKS}/g" \
       ../template/mkimage-profile.template > ${MEDIR}/aports/scripts/mkimg.$PROFILENAME.sh

# cat << EOF > ${MEDIR}/aports/scripts/mkimg.$PROFILENAME.sh
# profile_$PROFILENAME() {
#         profile_standard
#         kernel_cmdline="unionfs_size=512M console=tty0 console=ttyS0,115200"
#         syslinux_serial="0 115200"
#         # remove packages not needed for conversion
#         apks="\$apks avahi btrfs-progs coreutils cups cups-filters curl dosfstools
#               gawk hplip mc mdadm nano net-snmp nfs-utils ntfs-3g proftpd
#               rsync samba sane sane-backends shadow util-linux vim
#              "
#         local _k _a
#         for _k in \$kernel_flavors; do
#                 apks="\$apks linux-\$_k"
#                 for _a in \$kernel_addons; do
#                         apks="\$apks \$_a-\$_k"
#                 done
#         done
#         apks="\$apks linux-firmware"
#         apks="\${apks//network-extras }"
#         apks="\${apks//openntpd }"
#         apks="\${apks//tiny-cloud-alpine }"
#         apks="\${apks//iw }"
#         apks="\${apks//wpa_supplicant }"
#         echo "APKs baked into ISO:"
#         echo "\$apks"
#         hostname="rnxpine"
#         apkovl="genapkovl-${PROFILENAME}.sh"
# }
# EOF

chmod +x ${MEDIR}/aports/scripts/mkimg.$PROFILENAME.sh

# This is the script that will generate an `$HOSTNAME.apkovl.tar.gz` that
# will get baked into the `*.iso`. You could say this is the good stuff.
#
# And most of it is stolen^Wcopied from: scripts/genapkovl-dhcp.sh

echo "generating ${MEDIR}/aports/scripts/genapkovl-${PROFILENAME}.sh"
cat ../template/genapkovl.template > ${MEDIR}/aports/scripts/genapkovl-${PROFILENAME}.sh
chmod +x ${MEDIR}/aports/scripts/genapkovl-${PROFILENAME}.sh

# Make sure we're NOT working in RAM since we may be
# running on a RAM-challenged system. If you have plenty
# of RAM (> 4GB) comment the next two lines to speed
# up the build process

mkdir -p ${MEDIR}/iso_tmp
export TMPDIR=${MEDIR}/iso_tmp

# Pat-a-cake, pat-a-cake, mkimage man,
# Bake me an iso, as fast as you can;
# Fetch stuff, and mold it, and augment it with preseed,
# Put it in the ~/iso folder, for I have that need.
cd ${MEDIR}/aports/scripts/

# build different isos for different Keymaps
KEYMAPS="de us"
for MAP in ${KEYMAPS}; do
  export KEYMAP=${MAP}

  sh mkimage.sh --tag "${GITREV}_${KEYMAP}" \
    --outdir ${MEDIR}/iso \
    --arch x86_64 \
    --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/main \
    --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/community \
    --profile $PROFILENAME
done