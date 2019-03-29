#!/bin/bash

set -e

repo='https://github.com/archlinux/arch-boxes/raw/master'
logfile=$(mktemp)

import-if-non-existent() {
    if [ ! -e "$1" ]; then
	echo ">>> Fetching: $1"
	curl -L "$repo/$1" -o "$1" >$logfile 2>&1 || echo ">>> ERROR: check $logfile"
    fi
}

import-if-non-existent 'http/install-chroot.sh'
import-if-non-existent 'http/install.sh'
import-if-non-existent 'provision/cleanup.sh'
import-if-non-existent 'provision/qemu.sh'
import-if-non-existent 'provision/postinstall.sh'
