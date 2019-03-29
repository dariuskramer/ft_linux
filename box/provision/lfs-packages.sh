#!/bin/bash

set -xe

set -x

sudo pacman -Syu --needed --noconfirm wget

srcdir='/home/vagrant/lfs-packages'
mkdir -p $srcdir
cd $srcdir
wget --no-verbose -N 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list'
wget --no-verbose -N 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums'
wget --no-verbose -N --input-file=wget-list --continue
md5sum -c md5sums
