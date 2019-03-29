#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*%5B%5Bhttp://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/creatingdirs.html%5D%5B6.5.%C2%A0Creating%20Directories%5D%5D][[[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/creatingdirs.html][6.5. Creating Directories]]:1]]
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
# [[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/creatingdirs.html][6.5. Creating Directories]]:1 ends here

# [[file:~/org/projects/ft_linux.org::*%5B%5Bhttp://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/createfiles.html%5D%5B6.6.%C2%A0Creating%20Essential%20Files%20and%20Symlinks%5D%5D][[[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/createfiles.html][6.6. Creating Essential Files and Symlinks]]:1]]
ln -sv /tools/bin/{bash,cat,chmod,dd,echo,ln,mkdir,pwd,rm,stty,touch} /bin
ln -sv /tools/bin/{env,install,perl,printf}         /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1}                  /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}}             /usr/lib

install -vdm755 /usr/lib/pkgconfig

ln -sv bash /bin/sh

ln -sv /proc/self/mounts /etc/mtab
# [[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/createfiles.html][6.6. Creating Essential Files and Symlinks]]:1 ends here

# [[file:~/org/projects/ft_linux.org::users-and-groups][users-and-groups]]
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
systemd-bus-proxy:x:72:72:systemd Bus Proxy:/:/bin/false
systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/bin/false
systemd-journal-remote:x:74:74:systemd Journal Remote:/:/bin/false
systemd-journal-upload:x:75:75:systemd Journal Upload:/:/bin/false
systemd-network:x:76:76:systemd Network Management:/:/bin/false
systemd-resolve:x:77:77:systemd Resolver:/:/bin/false
systemd-timesync:x:78:78:systemd Time Synchronization:/:/bin/false
systemd-coredump:x:79:79:systemd Core Dumper:/:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF

cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
systemd-journal:x:23:
input:x:24:
mail:x:34:
kvm:x:61:
systemd-bus-proxy:x:72:
systemd-journal-gateway:x:73:
systemd-journal-remote:x:74:
systemd-journal-upload:x:75:
systemd-network:x:76:
systemd-resolve:x:77:
systemd-timesync:x:78:
systemd-coredump:x:79:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF
# users-and-groups ends here
