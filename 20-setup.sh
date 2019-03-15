#!/usr/bin/env sh

set -e

export LFS='/mnt/lfs'
export srcdir="${LFS}/src"
export toolsdir="${LFS}/tools"


# 3. Packages and Patches
mkdir -p $srcdir
chmod -v a+wt $srcdir
cd $srcdir

if ! test \( -f 'wget-list' -a -f 'md5sums' \); then
	wget --quiet 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/wget-list' \
		 'http://www.linuxfromscratch.org/lfs/view/stable-systemd/md5sums'

	while IFS='' read -r line || [[ -n "$line" ]]; do
		echo "Downloading $line"
		wget --quiet --continue --directory-prefix=$srcdir $line
	done < wget-list
else
	echo "Packages already downloaded"
fi

echo "Start checking md5sums"
md5sum -c md5sums


# 4. Final Preparations
mkdir -p $toolsdir
ln -vfs $toolsdir /
groupadd -f lfs
grep --silent lfs /etc/passwd || useradd -s /bin/bash -g lfs -m -k /dev/null lfs
chown -v lfs $toolsdir $srcdir
ln -vfs /vagrant/bash_profile /home/lfs/.bash_profile
ln -vfs /vagrant/bashrc /home/lfs/.bashrc


# Done!
echo "Setup finished!"
