#!/bin/sh

cd aports/scripts
sh mkimage.sh --tag v3.18-rnx \
 --outdir /home/build/rnx-alpine/build_user/iso \
 --arch x86_64 \
 --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/main \
 --repository http://dl-cdn.alpinelinux.org/alpine/v3.18/community \
 --profile rnxpine
 cd -