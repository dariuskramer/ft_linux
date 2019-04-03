#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:1]]
LFS='/mnt/lfs'
LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
pacman -S --needed --noconfirm parted
# Configuration du disque de destination pour /LFS/:1 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:2]]
if ! partprobe --dry-run --summary ${LFS_DEVICE} | fgrep --silent '3'; then
    echo '>>> Partition LFS disk'
    parted --script --align minimal ${LFS_DEVICE} -- \
	   mklabel msdos \
	   mkpart primary ext2 1MiB 1GiB \
	   set 1 boot on \
	   mkpart primary linux-swap 1GiB 3GiB \
	   mkpart primary ext4 3GiB 100%

    echo '>>> Format LFS disk'
    mkfs.ext2 -L boot ${LFS_DEVICE}1
    mkswap    -L swap ${LFS_DEVICE}2
    mkfs.ext4 -L lfs  ${LFS_DEVICE}3
fi
# Configuration du disque de destination pour /LFS/:2 ends here

# [[file:~/org/projects/ft_linux.org::*Configuration%20du%20disque%20de%20destination%20pour%20/LFS/][Configuration du disque de destination pour /LFS/:3]]
echo '>>> Mount LFS disk'
fgrep --silent ${LFS}      /proc/mounts || { mkdir -p ${LFS}      && mount ${LFS_DEVICE}3 ${LFS}      ; }
fgrep --silent ${LFS}/boot /proc/mounts || { mkdir -p ${LFS}/boot && mount ${LFS_DEVICE}1 ${LFS}/boot ; }
# Configuration du disque de destination pour /LFS/:3 ends here
