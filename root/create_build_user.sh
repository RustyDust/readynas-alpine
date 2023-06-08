#!/bin/sh

# See https://wejn.org/2022/04/alpinelinux-unattended-install/#fn2

# Preflight
if test $(id -u) -ne 0; then
  echo "Maybe you want to run this as root, eh?"
  exit 111
fi

if test ! -f /etc/apk/world; then
  echo "Maybe you should be running this from alpine, dawg?"
  exit 111
fi

TEST=`grep community /etc/apk/repositories`
if [ -z ${TEST} ]; then
  echo "The community repository must be enabled!"
  exit 111;
fi
if [ "${TEST:0:1}" = "#" ]; then
  echo "Community repo present but disabled: enabling"
  sed -i -r 's,#(.*/v.*/community),\1,' /etc/apk/repositories
fi

# =--------------------------------------------------------------------=
# This is mostly from the "How to make a custom ISO image" wiki article.
# My claim to fame is the preseed part.
# =--------------------------------------------------------------------=

# refresh package list
apk update
apk upgrade

# Packages you'll need
# `sudo` requires the community repository!!
apk add alpine-sdk build-base apk-tools alpine-conf busybox fakeroot 
apk add syslinux xorriso squashfs-tools sudo grub

# User setup
adduser build -G abuild -D

# Grant unrestricted sudo to abuild group
echo "%abuild ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/abuild
