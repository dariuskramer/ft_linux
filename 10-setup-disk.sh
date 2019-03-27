#!/bin/bash

set -e

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:1]]
LFS='/mnt/lfs'
LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
pacman -Syu --needed --noconfirm parted
# Configuration du disque de destination pour /LFS/:1 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:2]]
umount --quiet --recursive ${LFS} || true
# Configuration du disque de destination pour /LFS/:2 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:3]]
parted --script --align minimal ${LFS_DEVICE} -- \
       mklabel msdos \
       mkpart primary ext2 1MiB 1GiB \
       set 1 boot on \
       mkpart primary linux-swap 1GiB 3GiB \
       mkpart primary ext4 3GiB 100%
# Configuration du disque de destination pour /LFS/:3 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:4]]
mkfs.ext2 -L boot ${LFS_DEVICE}1
mkswap    -L swap ${LFS_DEVICE}2
mkfs.ext4 -L lfs  ${LFS_DEVICE}3
# Configuration du disque de destination pour /LFS/:4 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:5]]
mkdir -p ${LFS}      && mount ${LFS_DEVICE}3 ${LFS}
mkdir -p ${LFS}/boot && mount ${LFS_DEVICE}1 ${LFS}/boot
# Configuration du disque de destination pour /LFS/:5 ends here
