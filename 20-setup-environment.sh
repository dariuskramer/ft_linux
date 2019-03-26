#!/bin/bash

set -e

LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
LFS='/mnt/lfs'
pacman -Syu --needed --noconfirm wget

srcdir="${LFS}/sources"
mkdir -p $srcdir
chmod -v a+wt $srcdir
wget --no-verbose --directory-prefix=$srcdir 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list'
wget --no-verbose --directory-prefix=$srcdir 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums'
wget --no-verbose --directory-prefix=$srcdir --input-file=wget-list --continue
pushd $srcdir
md5sum -c md5sums
popd

LFS_DEVICE='/dev/vdb'
LFS_GROUP='vagrant'
LFS_USER='vagrant'
LFS='/mnt/lfs'
toolsdir="${LFS}/tools"

mkdir -p $toolsdir
ln -vfs $toolsdir /

grep --silent ${LFS_GROUP} /etc/group  || groupadd -f ${LFS_GROUP}
grep --silent ${LFS_USER} /etc/passwd || useradd -s /bin/bash -g ${LFS_GROUP} -m -k /dev/null ${LFS_USER}
chown -v ${LFS_USER} $toolsdir $srcdir

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
