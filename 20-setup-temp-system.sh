#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*Configurer%20l'environnement%20du%20syst%C3%A8me%20temporaire][Configurer l'environnement du système temporaire:1]]
LFS='/mnt/lfs'
LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
toolsdir="${LFS}/tools"
srcdir="${LFS}/sources"

mkdir -p $toolsdir $srcdir
ln -vfs $toolsdir /
mount -v --bind /home/vagrant/lfs-packages $srcdir

grep --silent ${LFS_GROUP} /etc/group  || groupadd -f ${LFS_GROUP}
grep --silent ${LFS_USER} /etc/passwd || useradd -s /bin/bash -g ${LFS_GROUP} -m -k /dev/null ${LFS_USER}
chown -Rv ${LFS_USER} $toolsdir $srcdir

cat > /home/${LFS_USER}/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF

cat > /home/${LFS_USER}/.bashrc << EOF
set +h
umask 022
export LFS=$LFS
export LC_ALL=POSIX
export LFS_TGT=\$(uname -m)-lfs-linux-gnu
export PATH=/tools/bin:/bin:/usr/bin
export MAKEFLAGS='-j 8'
EOF
# Configurer l'environnement du système temporaire:1 ends here
