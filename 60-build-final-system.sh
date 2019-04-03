#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::log-files][log-files]]
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
# log-files ends here

# [[file:~/org/projects/ft_linux.org::*Dans%20le%20~chroot~,%20installer%20les%20outils%20basique%20du%20syst%C3%A8me%20de%20destination][Dans le ~chroot~, installer les outils basique du système de destination:2]]
cd /sources
# Dans le ~chroot~, installer les outils basique du système de destination:2 ends here

# [[file:~/org/projects/ft_linux.org::build-linux-4.20.12][build-linux-4.20.12]]
tar -xf linux-4.20.12.tar.xz
echo '>>> Building linux-4.20.12'
pushd 'linux-4.20.12'

make mrproper

make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include

popd
rm -rf 'linux-4.20.12'
# build-linux-4.20.12 ends here

# [[file:~/org/projects/ft_linux.org::build-man-pages-4.16][build-man-pages-4.16]]
tar -xf man-pages-4.16.tar.xz
echo '>>> Building man-pages-4.16'
pushd 'man-pages-4.16'

make install

popd
rm -rf 'man-pages-4.16'
# build-man-pages-4.16 ends here

# [[file:~/org/projects/ft_linux.org::build-glibc-2.29][build-glibc-2.29]]
tar -xf glibc-2.29.tar.xz
echo '>>> Building glibc-2.29'
pushd 'glibc-2.29'

patch -Np1 -i ../glibc-2.29-fhs-1.patch

ln -sfv /tools/lib/gcc /usr/lib

case $(uname -m) in
    i?86)    GCC_INCDIR=/usr/lib/gcc/$(uname -m)-pc-linux-gnu/8.2.0/include
            ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) GCC_INCDIR=/usr/lib/gcc/x86_64-pc-linux-gnu/8.2.0/include
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac
rm -f /usr/include/limits.h

mkdir -v build
cd       build

CC="gcc -isystem $GCC_INCDIR -isystem /usr/include" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             libc_cv_slibdir=/lib
unset GCC_INCDIR

make

case $(uname -m) in
  i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac

#make check

touch /etc/ld.so.conf
sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile

make install

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd

install -v -Dm644 ../nscd/nscd.tmpfiles /usr/lib/tmpfiles.d/nscd.conf
install -v -Dm644 ../nscd/nscd.service /lib/systemd/system/nscd.service

mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS

cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF

tar -xf ../../tzdata2018i.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO

ln -sfv /usr/share/zoneinfo/Europe/Paris /etc/localtime

cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib
include /etc/ld.so.conf.d/*.conf
EOF
mkdir -pv /etc/ld.so.conf.d

popd
rm -rf 'glibc-2.29'
# build-glibc-2.29 ends here

# [[file:~/org/projects/ft_linux.org::*%5B%5Bhttp://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/adjusting.html%5D%5B6.10.%C2%A0Adjusting%20the%20Toolchain%5D%5D][[[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/adjusting.html][6.10. Adjusting the Toolchain]]:1]]
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld

gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B1 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
# [[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/adjusting.html][6.10. Adjusting the Toolchain]]:1 ends here

# [[file:~/org/projects/ft_linux.org::build-zlib-1.2.11][build-zlib-1.2.11]]
tar -xf zlib-1.2.11.tar.xz
echo '>>> Building zlib-1.2.11'
pushd 'zlib-1.2.11'

./configure --prefix=/usr
make
make check
make install

mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so

popd
rm -rf 'zlib-1.2.11'
# build-zlib-1.2.11 ends here

# [[file:~/org/projects/ft_linux.org::build-file-5.36][build-file-5.36]]
tar -xf file-5.36.tar.gz
echo '>>> Building file-5.36'
pushd 'file-5.36'

./configure --prefix=/usr
make
make check
make install

popd
rm -rf 'file-5.36'
# build-file-5.36 ends here

# [[file:~/org/projects/ft_linux.org::build-readline-8.0][build-readline-8.0]]
tar -xf readline-8.0.tar.gz
echo '>>> Building readline-8.0'
pushd 'readline-8.0'

sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-8.0

make SHLIB_LIBS="-L/tools/lib -lncursesw"
make SHLIB_LIBS="-L/tools/lib -lncursesw" install

mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so

install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0

popd
rm -rf 'readline-8.0'
# build-readline-8.0 ends here

# [[file:~/org/projects/ft_linux.org::build-m4-1.4.18][build-m4-1.4.18]]
tar -xf m4-1.4.18.tar.xz
echo '>>> Building m4-1.4.18'
pushd 'm4-1.4.18'

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/usr
make
make check
make install

popd
rm -rf 'm4-1.4.18'
# build-m4-1.4.18 ends here

# [[file:~/org/projects/ft_linux.org::build-bc-1.07.1][build-bc-1.07.1]]
tar -xf bc-1.07.1.tar.gz
echo '>>> Building bc-1.07.1'
pushd 'bc-1.07.1'

cat > bc/fix-libmath_h << "EOF"
#! /bin/bash
sed -e '1   s/^/{"/' \
    -e     's/$/",/' \
    -e '2,$ s/^/"/'  \
    -e   '$ d'       \
    -i libmath.h

sed -e '$ s/$/0}/' \
    -i libmath.h
EOF

ln -sv /tools/lib/libncursesw.so.6 /usr/lib/libncursesw.so.6
ln -sfv libncursesw.so.6 /usr/lib/libncurses.so

sed -i -e '/flex/s/as_fn_error/: ;; # &/' configure

./configure --prefix=/usr           \
            --with-readline         \
            --mandir=/usr/share/man \
            --infodir=/usr/share/info

make
#echo "quit" | ./bc/bc -l Test/checklib.b
make install

popd
rm -rf 'bc-1.07.1'
# build-bc-1.07.1 ends here

# [[file:~/org/projects/ft_linux.org::build-binutils-2.32][build-binutils-2.32]]
tar -xf binutils-2.32.tar.xz
echo '>>> Building binutils-2.32'
pushd 'binutils-2.32'

expect -c "spawn ls" | grep 'spawn ls'

mkdir -v build
cd       build

../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make tooldir=/usr
#make -k check
make tooldir=/usr install

popd
rm -rf 'binutils-2.32'
# build-binutils-2.32 ends here

# [[file:~/org/projects/ft_linux.org::build-gmp-6.1.2][build-gmp-6.1.2]]
tar -xf gmp-6.1.2.tar.xz
echo '>>> Building gmp-6.1.2'
pushd 'gmp-6.1.2'

cp -v configfsf.guess config.guess
cp -v configfsf.sub   config.sub

./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --build=x86_64-unknown-linux-gnu \
            --docdir=/usr/share/doc/gmp-6.1.2

make
make html
make check 2>&1 | tee gmp-check-log
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
make install
make install-html

popd
rm -rf 'gmp-6.1.2'
# build-gmp-6.1.2 ends here

# [[file:~/org/projects/ft_linux.org::build-mpfr-4.0.2][build-mpfr-4.0.2]]
tar -xf mpfr-4.0.2.tar.xz
echo '>>> Building mpfr-4.0.2'
pushd 'mpfr-4.0.2'

./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.2

make
make html
make check
make install
make install-html

popd
rm -rf 'mpfr-4.0.2'
# build-mpfr-4.0.2 ends here

# [[file:~/org/projects/ft_linux.org::build-mpc-1.1.0][build-mpc-1.1.0]]
tar -xf mpc-1.1.0.tar.gz
echo '>>> Building mpc-1.1.0'
pushd 'mpc-1.1.0'

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make
make html
make check
make install
make install-html

popd
rm -rf 'mpc-1.1.0'
# build-mpc-1.1.0 ends here

# [[file:~/org/projects/ft_linux.org::build-shadow-4.6][build-shadow-4.6]]
tar -xf shadow-4.6.tar.xz
echo '>>> Building shadow-4.6'
pushd 'shadow-4.6'

sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32
make
make install

mv -v /usr/bin/passwd /bin

pwconv
grpconv
sed -i 's/yes/no/' /etc/default/useradd
echo 'root:password' | chpasswd

popd
rm -rf 'shadow-4.6'
# build-shadow-4.6 ends here

# [[file:~/org/projects/ft_linux.org::build-gcc-8.2.0][build-gcc-8.2.0]]
tar -xf gcc-8.2.0.tar.xz
echo '>>> Building gcc-8.2.0'
pushd 'gcc-8.2.0'

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
  ;;
esac

rm -f /usr/lib/gcc

mkdir -v build
cd       build

SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --disable-libmpx         \
             --with-system-zlib

make

#ulimit -s 32768
#rm ../gcc/testsuite/g++.dg/pr83239.C
#chown -Rv nobody . 
#su nobody -s /bin/bash -c "PATH=$PATH make -k check" || true

make install
ln -sv ../usr/bin/cpp /lib
ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/8.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/

echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'

grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
grep -B4 '^ /usr/include' dummy.log
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
grep "/lib.*/libc.so.6 " dummy.log
grep found dummy.log
rm -v dummy.c a.out dummy.log
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib

popd
rm -rf 'gcc-8.2.0'
# build-gcc-8.2.0 ends here

# [[file:~/org/projects/ft_linux.org::build-bzip2-1.0.6][build-bzip2-1.0.6]]
tar -xf bzip2-1.0.6.tar.gz
echo '>>> Building bzip2-1.0.6'
pushd 'bzip2-1.0.6'

patch -Np1 -i ../bzip2-1.0.6-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile

make -f Makefile-libbz2_so
make clean
make
make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat

popd
rm -rf 'bzip2-1.0.6'
# build-bzip2-1.0.6 ends here

# [[file:~/org/projects/ft_linux.org::build-pkg-config-0.29.2][build-pkg-config-0.29.2]]
tar -xf pkg-config-0.29.2.tar.gz
echo '>>> Building pkg-config-0.29.2'
pushd 'pkg-config-0.29.2'

./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2
make
make check
make install

popd
rm -rf 'pkg-config-0.29.2'
# build-pkg-config-0.29.2 ends here

# [[file:~/org/projects/ft_linux.org::build-ncurses-6.1][build-ncurses-6.1]]
tar -xf ncurses-6.1.tar.gz
echo '>>> Building ncurses-6.1'
pushd 'ncurses-6.1'

sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec

make
make install

mv -v /usr/lib/libncursesw.so.6* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so

for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done

rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so

mkdir -v       /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1

popd
rm -rf 'ncurses-6.1'
# build-ncurses-6.1 ends here

# [[file:~/org/projects/ft_linux.org::build-attr-2.4.48][build-attr-2.4.48]]
tar -xf attr-2.4.48.tar.gz
echo '>>> Building attr-2.4.48'
pushd 'attr-2.4.48'

./configure --prefix=/usr     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48
make
make check
make install

mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so

popd
rm -rf 'attr-2.4.48'
# build-attr-2.4.48 ends here

# [[file:~/org/projects/ft_linux.org::build-acl-2.2.53][build-acl-2.2.53]]
tar -xf acl-2.2.53.tar.gz
echo '>>> Building acl-2.2.53'
pushd 'acl-2.2.53'

./configure --prefix=/usr         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53
make
make install

mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so

popd
rm -rf 'acl-2.2.53'
# build-acl-2.2.53 ends here

# [[file:~/org/projects/ft_linux.org::build-libcap-2.26][build-libcap-2.26]]
tar -xf libcap-2.26.tar.xz
echo '>>> Building libcap-2.26'
pushd 'libcap-2.26'

sed -i '/install.*STALIBNAME/d' libcap/Makefile
make
make RAISE_SETFCAP=no lib=lib prefix=/usr install
chmod -v 755 /usr/lib/libcap.so.2.26

mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so

popd
rm -rf 'libcap-2.26'
# build-libcap-2.26 ends here

# [[file:~/org/projects/ft_linux.org::build-sed-4.7][build-sed-4.7]]
tar -xf sed-4.7.tar.xz
echo '>>> Building sed-4.7'
pushd 'sed-4.7'

sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in

./configure --prefix=/usr --bindir=/bin
make
make html
make check
make install
install -d -m755           /usr/share/doc/sed-4.7
install -m644 doc/sed.html /usr/share/doc/sed-4.7

popd
rm -rf 'sed-4.7'
# build-sed-4.7 ends here

# [[file:~/org/projects/ft_linux.org::build-psmisc-23.2][build-psmisc-23.2]]
tar -xf psmisc-23.2.tar.xz
echo '>>> Building psmisc-23.2'
pushd 'psmisc-23.2'

./configure --prefix=/usr
make
make install

mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin

popd
rm -rf 'psmisc-23.2'
# build-psmisc-23.2 ends here

# [[file:~/org/projects/ft_linux.org::build-iana-etc-2.30][build-iana-etc-2.30]]
tar -xf iana-etc-2.30.tar.bz2
echo '>>> Building iana-etc-2.30'
pushd 'iana-etc-2.30'

make
make install

popd
rm -rf 'iana-etc-2.30'
# build-iana-etc-2.30 ends here

# [[file:~/org/projects/ft_linux.org::build-bison-3.3.2][build-bison-3.3.2]]
tar -xf bison-3.3.2.tar.xz
echo '>>> Building bison-3.3.2'
pushd 'bison-3.3.2'

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.3.2
make
make install

popd
rm -rf 'bison-3.3.2'
# build-bison-3.3.2 ends here

# [[file:~/org/projects/ft_linux.org::build-flex-2.6.4][build-flex-2.6.4]]
tar -xf flex-2.6.4.tar.gz
echo '>>> Building flex-2.6.4'
pushd 'flex-2.6.4'

sed -i "/math.h/a #include <malloc.h>" src/flexdef.h
HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4

make
make check
make install

ln -sv flex /usr/bin/lex

popd
rm -rf 'flex-2.6.4'
# build-flex-2.6.4 ends here

# [[file:~/org/projects/ft_linux.org::build-grep-3.3][build-grep-3.3]]
tar -xf grep-3.3.tar.xz
echo '>>> Building grep-3.3'
pushd 'grep-3.3'

./configure --prefix=/usr --bindir=/bin
make
make -k check
make install

popd
rm -rf 'grep-3.3'
# build-grep-3.3 ends here

# [[file:~/org/projects/ft_linux.org::build-bash-5.0][build-bash-5.0]]
tar -xf bash-5.0.tar.gz
echo '>>> Building bash-5.0'
pushd 'bash-5.0'

./configure --prefix=/usr                    \
            --docdir=/usr/share/doc/bash-5.0 \
            --without-bash-malloc            \
            --with-installed-readline
make
make install

mv -vf /usr/bin/bash /bin

#exec /bin/bash --login +h

popd
rm -rf 'bash-5.0'
# build-bash-5.0 ends here

# [[file:~/org/projects/ft_linux.org::build-libtool-2.4.6][build-libtool-2.4.6]]
tar -xf libtool-2.4.6.tar.xz
echo '>>> Building libtool-2.4.6'
pushd 'libtool-2.4.6'

./configure --prefix=/usr
make
#make check TESTSUITEFLAGS=-j8
make install

popd
rm -rf 'libtool-2.4.6'
# build-libtool-2.4.6 ends here

# [[file:~/org/projects/ft_linux.org::build-gdbm-1.18.1][build-gdbm-1.18.1]]
tar -xf gdbm-1.18.1.tar.gz
echo '>>> Building gdbm-1.18.1'
pushd 'gdbm-1.18.1'

./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat
make
make check
make install

popd
rm -rf 'gdbm-1.18.1'
# build-gdbm-1.18.1 ends here

# [[file:~/org/projects/ft_linux.org::build-gperf-3.1][build-gperf-3.1]]
tar -xf gperf-3.1.tar.gz
echo '>>> Building gperf-3.1'
pushd 'gperf-3.1'

./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
make
make -j1 check
make install

popd
rm -rf 'gperf-3.1'
# build-gperf-3.1 ends here

# [[file:~/org/projects/ft_linux.org::build-expat-2.2.6][build-expat-2.2.6]]
tar -xf expat-2.2.6.tar.bz2
echo '>>> Building expat-2.2.6'
pushd 'expat-2.2.6'

sed -i 's|usr/bin/env |bin/|' run.sh.in

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.6
make
make check
make install
install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.6

popd
rm -rf 'expat-2.2.6'
# build-expat-2.2.6 ends here

# [[file:~/org/projects/ft_linux.org::build-inetutils-1.9.4][build-inetutils-1.9.4]]
tar -xf inetutils-1.9.4.tar.xz
echo '>>> Building inetutils-1.9.4'
pushd 'inetutils-1.9.4'

./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers
make
#make check
make install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin

popd
rm -rf 'inetutils-1.9.4'
# build-inetutils-1.9.4 ends here

# [[file:~/org/projects/ft_linux.org::build-perl-5.28.1][build-perl-5.28.1]]
tar -xf perl-5.28.1.tar.xz
echo '>>> Building perl-5.28.1'
pushd 'perl-5.28.1'

echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads

make
#make check
make install
unset BUILD_ZLIB BUILD_BZIP2

popd
rm -rf 'perl-5.28.1'
# build-perl-5.28.1 ends here

# [[file:~/org/projects/ft_linux.org::build-XML-Parser-2.44][build-XML-Parser-2.44]]
tar -xf XML-Parser-2.44.tar.gz
echo '>>> Building XML-Parser-2.44'
pushd 'XML-Parser-2.44'

perl Makefile.PL
make
make test
make install

popd
rm -rf 'XML-Parser-2.44'
# build-XML-Parser-2.44 ends here

# [[file:~/org/projects/ft_linux.org::build-intltool-0.51.0][build-intltool-0.51.0]]
tar -xf intltool-0.51.0.tar.gz
echo '>>> Building intltool-0.51.0'
pushd 'intltool-0.51.0'

sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr
make
make check
make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO

popd
rm -rf 'intltool-0.51.0'
# build-intltool-0.51.0 ends here

# [[file:~/org/projects/ft_linux.org::build-autoconf-2.69][build-autoconf-2.69]]
tar -xf autoconf-2.69.tar.xz
echo '>>> Building autoconf-2.69'
pushd 'autoconf-2.69'

sed '361 s/{/\\{/' -i bin/autoscan.in

./configure --prefix=/usr
make
#make check
make install

popd
rm -rf 'autoconf-2.69'
# build-autoconf-2.69 ends here

# [[file:~/org/projects/ft_linux.org::build-automake-1.16.1][build-automake-1.16.1]]
tar -xf automake-1.16.1.tar.xz
echo '>>> Building automake-1.16.1'
pushd 'automake-1.16.1'

./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
make
#make -j8 check
make install

popd
rm -rf 'automake-1.16.1'
# build-automake-1.16.1 ends here

# [[file:~/org/projects/ft_linux.org::build-xz-5.2.4][build-xz-5.2.4]]
tar -xf xz-5.2.4.tar.xz
echo '>>> Building xz-5.2.4'
pushd 'xz-5.2.4'

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4
make
make check
make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so

popd
rm -rf 'xz-5.2.4'
# build-xz-5.2.4 ends here

# [[file:~/org/projects/ft_linux.org::build-kmod-26][build-kmod-26]]
tar -xf kmod-26.tar.xz
echo '>>> Building kmod-26'
pushd 'kmod-26'

./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib
make
make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/$target
done

ln -sfv kmod /bin/lsmod

popd
rm -rf 'kmod-26'
# build-kmod-26 ends here

# [[file:~/org/projects/ft_linux.org::build-gettext-0.19.8.1][build-gettext-0.19.8.1]]
tar -xf gettext-0.19.8.1.tar.xz
echo '>>> Building gettext-0.19.8.1'
pushd 'gettext-0.19.8.1'

sed -i '/^TESTS =/d' gettext-runtime/tests/Makefile.in &&
sed -i 's/test-lock..EXEEXT.//' gettext-tools/gnulib-tests/Makefile.in

sed -e '/AppData/{N;N;p;s/\.appdata\./.metainfo./}' \
    -i gettext-tools/its/appdata.loc

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.19.8.1
make
make check
make install
chmod -v 0755 /usr/lib/preloadable_libintl.so

popd
rm -rf 'gettext-0.19.8.1'
# build-gettext-0.19.8.1 ends here

# [[file:~/org/projects/ft_linux.org::build-elfutils-0.176][build-elfutils-0.176]]
tar -xf elfutils-0.176.tar.bz2
echo '>>> Building elfutils-0.176'
pushd 'elfutils-0.176'

./configure --prefix=/usr
make
make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig

popd
rm -rf 'elfutils-0.176'
# build-elfutils-0.176 ends here

# [[file:~/org/projects/ft_linux.org::build-libffi-3.2.1][build-libffi-3.2.1]]
tar -xf libffi-3.2.1.tar.gz
echo '>>> Building libffi-3.2.1'
pushd 'libffi-3.2.1'

sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in

./configure --prefix=/usr --disable-static --with-gcc-arch=x86-64
make
make check
make install

popd
rm -rf 'libffi-3.2.1'
# build-libffi-3.2.1 ends here

# [[file:~/org/projects/ft_linux.org::build-openssl-1.1.1a][build-openssl-1.1.1a]]
tar -xf openssl-1.1.1a.tar.gz
echo '>>> Building openssl-1.1.1a'
pushd 'openssl-1.1.1a'

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic
make
make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1a
cp -vfr doc/* /usr/share/doc/openssl-1.1.1a

popd
rm -rf 'openssl-1.1.1a'
# build-openssl-1.1.1a ends here

# [[file:~/org/projects/ft_linux.org::build-Python-3.7.2][build-Python-3.7.2]]
tar -xf Python-3.7.2.tar.xz
echo '>>> Building Python-3.7.2'
pushd 'Python-3.7.2'

./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes
make
make install
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so

install -v -dm755 /usr/share/doc/python-3.7.2/html 

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.2/html \
    -xvf ../python-3.7.2-docs-html.tar.bz2

popd
rm -rf 'Python-3.7.2'
# build-Python-3.7.2 ends here

# [[file:~/org/projects/ft_linux.org::build-ninja-1.9.0][build-ninja-1.9.0]]
tar -xf ninja-1.9.0.tar.gz
echo '>>> Building ninja-1.9.0'
pushd 'ninja-1.9.0'

export NINJAJOBS=8

sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc

python3 configure.py --bootstrap

python3 configure.py
./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja

popd
rm -rf 'ninja-1.9.0'
# build-ninja-1.9.0 ends here

# [[file:~/org/projects/ft_linux.org::build-meson-0.49.2][build-meson-0.49.2]]
tar -xf meson-0.49.2.tar.gz
echo '>>> Building meson-0.49.2'
pushd 'meson-0.49.2'

python3 setup.py build
python3 setup.py install --root=dest
cp -rv dest/* /

popd
rm -rf 'meson-0.49.2'
# build-meson-0.49.2 ends here

# [[file:~/org/projects/ft_linux.org::build-coreutils-8.30][build-coreutils-8.30]]
tar -xf coreutils-8.30.tar.xz
echo '>>> Building coreutils-8.30'
pushd 'coreutils-8.30'

patch -Np1 -i ../coreutils-8.30-i18n-1.patch

sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime

FORCE_UNSAFE_CONFIGURE=1 make
make install

mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,nice,sleep,touch} /bin

popd
rm -rf 'coreutils-8.30'
# build-coreutils-8.30 ends here

# [[file:~/org/projects/ft_linux.org::build-check-0.12.0][build-check-0.12.0]]
tar -xf check-0.12.0.tar.gz
echo '>>> Building check-0.12.0'
pushd 'check-0.12.0'

./configure --prefix=/usr
make
make check
make install

sed -i '1 s/tools/usr/' /usr/bin/checkmk

popd
rm -rf 'check-0.12.0'
# build-check-0.12.0 ends here

# [[file:~/org/projects/ft_linux.org::build-diffutils-3.7][build-diffutils-3.7]]
tar -xf diffutils-3.7.tar.xz
echo '>>> Building diffutils-3.7'
pushd 'diffutils-3.7'

./configure --prefix=/usr
make
make check
make install

popd
rm -rf 'diffutils-3.7'
# build-diffutils-3.7 ends here

# [[file:~/org/projects/ft_linux.org::build-gawk-4.2.1][build-gawk-4.2.1]]
tar -xf gawk-4.2.1.tar.xz
echo '>>> Building gawk-4.2.1'
pushd 'gawk-4.2.1'

sed -i 's/extras//' Makefile.in

./configure --prefix=/usr
make
make check
make install

mkdir -v /usr/share/doc/gawk-4.2.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-4.2.1

popd
rm -rf 'gawk-4.2.1'
# build-gawk-4.2.1 ends here

# [[file:~/org/projects/ft_linux.org::build-findutils-4.6.0][build-findutils-4.6.0]]
tar -xf findutils-4.6.0.tar.gz
echo '>>> Building findutils-4.6.0'
pushd 'findutils-4.6.0'

sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/usr --localstatedir=/var/lib/locate
make
make check
make install

mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb

popd
rm -rf 'findutils-4.6.0'
# build-findutils-4.6.0 ends here

# [[file:~/org/projects/ft_linux.org::build-groff-1.22.4][build-groff-1.22.4]]
tar -xf groff-1.22.4.tar.gz
echo '>>> Building groff-1.22.4'
pushd 'groff-1.22.4'

PAGE=A4 ./configure --prefix=/usr
make -j1
make install

popd
rm -rf 'groff-1.22.4'
# build-groff-1.22.4 ends here

# [[file:~/org/projects/ft_linux.org::build-grub-2.02][build-grub-2.02]]
tar -xf grub-2.02.tar.xz
echo '>>> Building grub-2.02'
pushd 'grub-2.02'

./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror
make
make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions

popd
rm -rf 'grub-2.02'
# build-grub-2.02 ends here

# [[file:~/org/projects/ft_linux.org::build-less-530][build-less-530]]
tar -xf less-530.tar.gz
echo '>>> Building less-530'
pushd 'less-530'

./configure --prefix=/usr --sysconfdir=/etc
make
make install

popd
rm -rf 'less-530'
# build-less-530 ends here

# [[file:~/org/projects/ft_linux.org::build-gzip-1.10][build-gzip-1.10]]
tar -xf gzip-1.10.tar.xz
echo '>>> Building gzip-1.10'
pushd 'gzip-1.10'

./configure --prefix=/usr
make
#make check
make install
mv -v /usr/bin/gzip /bin

popd
rm -rf 'gzip-1.10'
# build-gzip-1.10 ends here

# [[file:~/org/projects/ft_linux.org::build-iproute2-4.20.0][build-iproute2-4.20.0]]
tar -xf iproute2-4.20.0.tar.xz
echo '>>> Building iproute2-4.20.0'
pushd 'iproute2-4.20.0'

sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

sed -i 's/.m_ipt.o//' tc/Makefile

make
make DOCDIR=/usr/share/doc/iproute2-4.20.0 install

popd
rm -rf 'iproute2-4.20.0'
# build-iproute2-4.20.0 ends here

# [[file:~/org/projects/ft_linux.org::build-kbd-2.0.4][build-kbd-2.0.4]]
tar -xf kbd-2.0.4.tar.xz
echo '>>> Building kbd-2.0.4'
pushd 'kbd-2.0.4'

patch -Np1 -i ../kbd-2.0.4-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
make
make check
make install

mkdir -v       /usr/share/doc/kbd-2.0.4
cp -R -v docs/doc/* /usr/share/doc/kbd-2.0.4

popd
rm -rf 'kbd-2.0.4'
# build-kbd-2.0.4 ends here

# [[file:~/org/projects/ft_linux.org::build-libpipeline-1.5.1][build-libpipeline-1.5.1]]
tar -xf libpipeline-1.5.1.tar.gz
echo '>>> Building libpipeline-1.5.1'
pushd 'libpipeline-1.5.1'

./configure --prefix=/usr
make
make check
make install

popd
rm -rf 'libpipeline-1.5.1'
# build-libpipeline-1.5.1 ends here

# [[file:~/org/projects/ft_linux.org::build-make-4.2.1][build-make-4.2.1]]
tar -xf make-4.2.1.tar.bz2
echo '>>> Building make-4.2.1'
pushd 'make-4.2.1'

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/usr
make
make PERL5LIB=$PWD/tests/ check
make install

popd
rm -rf 'make-4.2.1'
# build-make-4.2.1 ends here

# [[file:~/org/projects/ft_linux.org::build-patch-2.7.6][build-patch-2.7.6]]
tar -xf patch-2.7.6.tar.xz
echo '>>> Building patch-2.7.6'
pushd 'patch-2.7.6'

./configure --prefix=/usr
make
make check
make install

popd
rm -rf 'patch-2.7.6'
# build-patch-2.7.6 ends here

# [[file:~/org/projects/ft_linux.org::build-man-db-2.8.5][build-man-db-2.8.5]]
tar -xf man-db-2.8.5.tar.xz
echo '>>> Building man-db-2.8.5'
pushd 'man-db-2.8.5'

./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.5 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap
make
# make check (fail for ??? reasons)
make install

popd
rm -rf 'man-db-2.8.5'
# build-man-db-2.8.5 ends here

# [[file:~/org/projects/ft_linux.org::build-tar-1.31][build-tar-1.31]]
tar -xf tar-1.31.tar.xz
echo '>>> Building tar-1.31'
pushd 'tar-1.31'

sed -i 's/abort.*/FALLTHROUGH;/' src/extract.c

FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin
make
#make check (8GB file created)
make install
make -C doc install-html docdir=/usr/share/doc/tar-1.31

popd
rm -rf 'tar-1.31'
# build-tar-1.31 ends here

# [[file:~/org/projects/ft_linux.org::build-texinfo-6.5][build-texinfo-6.5]]
tar -xf texinfo-6.5.tar.xz
echo '>>> Building texinfo-6.5'
pushd 'texinfo-6.5'

sed -i '5481,5485 s/({/(\\{/' tp/Texinfo/Parser.pm

./configure --prefix=/usr --disable-static
make
make check
make install
make TEXMF=/usr/share/texmf install-tex

popd
rm -rf 'texinfo-6.5'
# build-texinfo-6.5 ends here

# [[file:~/org/projects/ft_linux.org::build-vim-8.1][build-vim-8.1]]
tar -xf vim-8.1.tar.bz2
echo '>>> Building vim-8.1'
pushd 'vim8.1'

echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h

./configure --prefix=/usr
make
#LANG=en_US.UTF-8 make -j1 test &> vim-test.log
make install

ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done

ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1

cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF

popd
rm -rf 'vim-8.1'
# build-vim-8.1 ends here

# [[file:~/org/projects/ft_linux.org::build-systemd-240][build-systemd-240]]
tar -xf systemd-240.tar.gz
echo '>>> Building systemd-240'
pushd 'systemd-240'

patch -Np1 -i ../systemd-240-security_fixes-2.patch

ln -sf /tools/bin/true /usr/bin/xsltproc

for file in /tools/lib/lib{blkid,mount,uuid}*; do
    ln -sf $file /usr/lib/
done

tar -xf ../systemd-man-pages-240.tar.xz

sed '177,$ d' -i src/resolve/meson.build

sed -i 's/GROUP="render", //' rules/50-udev-default.rules.in

mkdir -p build
cd       build

PKG_CONFIG_PATH="/usr/lib/pkgconfig:/tools/lib/pkgconfig" \
LANG=en_US.UTF-8                   \
meson --prefix=/usr                \
      --sysconfdir=/etc            \
      --localstatedir=/var         \
      -Dblkid=true                 \
      -Dbuildtype=release          \
      -Ddefault-dnssec=no          \
      -Dfirstboot=false            \
      -Dinstall-tests=false        \
      -Dkill-path=/bin/kill        \
      -Dkmod-path=/bin/kmod        \
      -Dldconfig=false             \
      -Dmount-path=/bin/mount      \
      -Drootprefix=                \
      -Drootlibdir=/lib            \
      -Dsplit-usr=true             \
      -Dsulogin-path=/sbin/sulogin \
      -Dsysusers=false             \
      -Dumount-path=/bin/umount    \
      -Db_lto=false                \
      ..

LANG=en_US.UTF-8 ninja
LANG=en_US.UTF-8 ninja install

rm -rfv /usr/lib/rpm
rm -f /usr/bin/xsltproc

systemd-machine-id-setup

cat > /lib/systemd/systemd-user-sessions << "EOF"
#!/bin/bash
rm -f /run/nologin
EOF
chmod 755 /lib/systemd/systemd-user-sessions

popd
rm -rf 'systemd-240'
# build-systemd-240 ends here

# [[file:~/org/projects/ft_linux.org::build-dbus-1.12.12][build-dbus-1.12.12]]
tar -xf dbus-1.12.12.tar.gz
echo '>>> Building dbus-1.12.12'
pushd 'dbus-1.12.12'

./configure --prefix=/usr                       \
            --sysconfdir=/etc                   \
            --localstatedir=/var                \
            --disable-static                    \
            --disable-doxygen-docs              \
            --disable-xml-docs                  \
            --docdir=/usr/share/doc/dbus-1.12.12 \
            --with-console-auth-dir=/run/console
make
make install

mv -v /usr/lib/libdbus-1.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libdbus-1.so) /usr/lib/libdbus-1.so

ln -sfv /etc/machine-id /var/lib/dbus

popd
rm -rf 'dbus-1.12.12'
# build-dbus-1.12.12 ends here

# [[file:~/org/projects/ft_linux.org::build-procps-ng-3.3.15][build-procps-ng-3.3.15]]
tar -xf procps-ng-3.3.15.tar.xz
echo '>>> Building procps-ng-3.3.15'
pushd 'procps-ng-3.3.15'

./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill                           \
            --with-systemd
make
#sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
#sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
#rm testsuite/pgrep.test/pgrep.exp
#make check
make install

mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so

popd
rm -rf 'procps-ng-3.3.15'
# build-procps-ng-3.3.15 ends here

# [[file:~/org/projects/ft_linux.org::build-util-linux-2.33.1][build-util-linux-2.33.1]]
tar -xf util-linux-2.33.1.tar.xz
echo '>>> Building util-linux-2.33.1'
pushd 'util-linux-2.33.1'

mkdir -pv /var/lib/hwclock
rm -vf /usr/include/{blkid,libmount,uuid}

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.33.1 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python
make
make install

popd
rm -rf 'util-linux-2.33.1'
# build-util-linux-2.33.1 ends here

# [[file:~/org/projects/ft_linux.org::build-e2fsprogs-1.44.5][build-e2fsprogs-1.44.5]]
tar -xf e2fsprogs-1.44.5.tar.gz
echo '>>> Building e2fsprogs-1.44.5'
pushd 'e2fsprogs-1.44.5'

mkdir -v build
cd build

../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck
make
make check
make install
make install-libs
chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info

popd
rm -rf 'e2fsprogs-1.44.5'
# build-e2fsprogs-1.44.5 ends here

# [[file:~/org/projects/ft_linux.org::*%5B%5Bhttp://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/revisedchroot.html%5D%5B6.79.%C2%A0Cleaning%20Up%5D%5D][[[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/revisedchroot.html][6.79. Cleaning Up]]:1]]
rm -rf /tmp/*
mv /tools{,-backup}
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a
find /usr/lib /usr/libexec -name \*.la -delete
# [[http://www.linuxfromscratch.org/lfs/view/stable-systemd/chapter06/revisedchroot.html][6.79. Cleaning Up]]:1 ends here
