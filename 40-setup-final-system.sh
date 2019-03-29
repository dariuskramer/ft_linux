#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*Configurer%20l'environnement%20du%20syst%C3%A8me%20final][Configurer l'environnement du système final:1]]
LFS='/mnt/lfs'
LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
chown -R root:root $LFS/tools
# Configurer l'environnement du système final:1 ends here

# [[file:~/org/projects/ft_linux.org::*%5B%5Bhttp://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/kernfs.html%5D%5B6.2.%C2%A0Preparing%20Virtual%20Kernel%20File%20Systems%5D%5D][[[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/kernfs.html][6.2. Preparing Virtual Kernel File Systems]]:1]]
mkdir -pv $LFS/{dev,proc,sys,run}

mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3

mount -v --bind /dev $LFS/dev
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
# [[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/kernfs.html][6.2. Preparing Virtual Kernel File Systems]]:1 ends here
