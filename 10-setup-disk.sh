#!/bin/bash

set -e

LFS_DEVICE='/dev/vdb'
LFS='/mnt/lfs'
pacman -Syu --needed --noconfirm parted

umount --quiet --recursive ${LFS} || true

parted --script --align minimal ${LFS_DEVICE} -- \
       mklabel msdos \
       mkpart primary ext2 1MiB 1GiB \
       set 1 boot on \
       mkpart primary linux-swap 1GiB 3GiB \
       mkpart primary ext4 3GiB 100%

mkfs.ext2 -L boot ${LFS_DEVICE}1
mkswap    -L swap ${LFS_DEVICE}2
mkfs.ext4 -L lfs  ${LFS_DEVICE}3

mkdir -p ${LFS}      && mount ${LFS_DEVICE}3 ${LFS}
mkdir -p ${LFS}/boot && mount ${LFS_DEVICE}1 ${LFS}/boot
