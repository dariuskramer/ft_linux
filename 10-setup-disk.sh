#!/bin/bash

set -e

LFS_DEVICE='/dev/sdb'
LFS_PATH='/mnt/lfs'
pacman -Syu --needed --noconfirm parted

umount --quiet --recursive ${LFS_PATH} || true

parted --script --align minimal ${LFS_DEVICE} -- \
       mklabel msdos \
       mkpart primary ext2 1MiB 1GiB \
       set 1 boot on \
       mkpart primary linux-swap 1GiB 3GiB \
       mkpart primary ext4 3GiB 100%

mkfs.ext2 -L boot /dev/sdb1
mkswap    -L swap /dev/sdb2
mkfs.ext4 -L lfs  /dev/sdb3

mkdir -p ${LFS_PATH}      && mount /dev/sdb3 ${LFS_PATH}
mkdir -p ${LFS_PATH}/boot && mount /dev/sdb1 ${LFS_PATH}/boot
