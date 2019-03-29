#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*Utilisation%20du%20~chroot~%20pour%20les%20%C3%A9tapes%20suivantes][Utilisation du ~chroot~ pour les étapes suivantes:1]]
LFS='/mnt/lfs'
LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
chroot "$LFS" /tools/bin/env -i                      \
       HOME=/root                                    \
       TERM="$TERM"                                  \
       PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
       /tools/bin/bash --login +h -- "$@"
# Utilisation du ~chroot~ pour les étapes suivantes:1 ends here
