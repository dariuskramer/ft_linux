#!/bin/bash

set -xe

# [[file:~/org/projects/ft_linux.org::*Construire%20le%20syst%C3%A8me%20temporaire][Construire le système temporaire:1]]
cd ${LFS}/sources
# Construire le système temporaire:1 ends here

# [[file:~/org/projects/ft_linux.org::binutils-pass-1][binutils-pass-1]]
tar -xf binutils-2.32.tar.xz
echo '>>> Building binutils-2.32 (Pass #1)'
pushd 'binutils-2.32'

mkdir -pv build
cd        build

../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
make install

popd
rm -rf binutils-2.32
# binutils-pass-1 ends here

# [[file:~/org/projects/ft_linux.org::gcc-pass-1][gcc-pass-1]]
tar -xf gcc-8.2.0.tar.xz
echo '>>> Building gcc-8.2.0 (Pass #1)'
pushd 'gcc-8.2.0'

tar -xf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac

mkdir -v build
cd       build

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++

make
make install

popd
rm -rf gcc-8.2.0
# gcc-pass-1 ends here

# [[file:~/org/projects/ft_linux.org::build-linux-api-headers][build-linux-api-headers]]
tar -xf linux-4.20.12.tar.xz
echo '>>> Building linux-4.20.12 API Headers'
pushd 'linux-4.20.12'

make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

popd
rm -rf linux-4.20.12
# build-linux-api-headers ends here

# [[file:~/org/projects/ft_linux.org::build-glibc][build-glibc]]
tar -xf glibc-2.29.tar.xz
echo '>>> Building glibc-2.29'
pushd 'glibc-2.29'

mkdir -v build
cd       build

../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include

make
make install

popd
rm -rf glibc-2.29
# build-glibc ends here

# [[file:~/org/projects/ft_linux.org::sanity-check][sanity-check]]
echo '>>> Doing Sanity Check'
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out
# sanity-check ends here

# [[file:~/org/projects/ft_linux.org::build-libstdc++][build-libstdc++]]
tar -xf gcc-8.2.0.tar.xz
echo '>>> Building libstdc++ from gcc-8.2.0'
pushd 'gcc-8.2.0'

mkdir -v build
cd       build

../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/8.2.0

make
make install

popd
rm -rf gcc-8.2.0
# build-libstdc++ ends here

# [[file:~/org/projects/ft_linux.org::build-binutils-pass-2][build-binutils-pass-2]]
tar -xf binutils-2.32.tar.xz
echo '>>> Building binutils-2.32'
pushd 'binutils-2.32'

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot

make
make install

make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin

popd
rm -rf 'binutils-2.32'
# build-binutils-pass-2 ends here

# [[file:~/org/projects/ft_linux.org::build-gcc-pass-2][build-gcc-pass-2]]
tar -xf gcc-8.2.0.tar.xz
echo '>>> Building gcc-8.2.0'
pushd 'gcc-8.2.0'

cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
    `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h

for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done

case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac

tar -xf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc

mkdir -v build
cd       build

CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp

make
make install

ln -sv gcc /tools/bin/cc

popd
rm -rf 'gcc-8.2.0'
# build-gcc-pass-2 ends here

# [[file:~/org/projects/ft_linux.org::sanity-check][sanity-check]]
echo '>>> Doing Sanity Check'
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
rm -v dummy.c a.out
# sanity-check ends here

# [[file:~/org/projects/ft_linux.org::build-tcl][build-tcl]]
tar -xf tcl8.6.9-src.tar.gz
echo '>>> Building tcl8.6.9'
pushd 'tcl8.6.9'

cd unix
./configure --prefix=/tools

make
make install

chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh

popd
rm -rf 'tcl8.6.9'
# build-tcl ends here

# [[file:~/org/projects/ft_linux.org::build-expect][build-expect]]
tar -xf expect5.45.4.tar.gz
echo '>>> Building expect5.45.4'
pushd 'expect5.45.4'

cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure

./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include

make
make SCRIPTS="" install

popd
rm -rf 'expect5.45.4'
# build-expect ends here

# [[file:~/org/projects/ft_linux.org::build-dejagnu][build-dejagnu]]
tar -xf dejagnu-1.6.2.tar.gz
echo '>>> Building dejagnu-1.6.2'
pushd 'dejagnu-1.6.2'

./configure --prefix=/tools
make install

popd
rm -rf 'dejagnu-1.6.2'
# build-dejagnu ends here

# [[file:~/org/projects/ft_linux.org::build-m4][build-m4]]
tar -xf m4-1.4.18.tar.xz
echo '>>> Building m4-1.4.18'
pushd 'm4-1.4.18'

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h

./configure --prefix=/tools

make
make install

popd
rm -rf 'm4-1.4.18'
# build-m4 ends here

# [[file:~/org/projects/ft_linux.org::build-ncurses][build-ncurses]]
tar -xf ncurses-6.1.tar.gz
echo '>>> Building ncurses-6.1'
pushd 'ncurses-6.1'

sed -i s/mawk// configure

./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite

make
make install
ln -s libncursesw.so /tools/lib/libncurses.so

popd
rm -rf 'ncurses-6.1'
# build-ncurses ends here

# [[file:~/org/projects/ft_linux.org::build-bash][build-bash]]
tar -xf bash-5.0.tar.gz
echo '>>> Building bash-5.0'
pushd 'bash-5.0'

./configure --prefix=/tools --without-bash-malloc

make
make install
ln -sv bash /tools/bin/sh

popd
rm -rf 'bash-5.0'
# build-bash ends here

# [[file:~/org/projects/ft_linux.org::build-bison][build-bison]]
tar -xf bison-3.3.2.tar.xz
echo '>>> Building bison-3.3.2'
pushd 'bison-3.3.2'

./configure --prefix=/tools
make
make install

popd
rm -rf 'bison-3.3.2'
# build-bison ends here

# [[file:~/org/projects/ft_linux.org::build-bzip2][build-bzip2]]
tar -xf bzip2-1.0.6.tar.gz
echo '>>> Building bzip2-1.0.6'
pushd 'bzip2-1.0.6'

make
make PREFIX=/tools install

popd
rm -rf 'bzip2-1.0.6'
# build-bzip2 ends here

# [[file:~/org/projects/ft_linux.org::build-coreutils-8.30][build-coreutils-8.30]]
tar -xf coreutils-8.30.tar.xz
echo '>>> Building coreutils-8.30'
pushd 'coreutils-8.30'

./configure --prefix=/tools --enable-install-program=hostname

make
make install

popd
rm -rf 'coreutils-8.30'
# build-coreutils-8.30 ends here

# [[file:~/org/projects/ft_linux.org::build-diffutils-3.7][build-diffutils-3.7]]
tar -xf diffutils-3.7.tar.xz
echo '>>> Building diffutils-3.7'
pushd 'diffutils-3.7'

./configure --prefix=/tools
make
make install

popd
rm -rf 'diffutils-3.7'
# build-diffutils-3.7 ends here

# [[file:~/org/projects/ft_linux.org::build-file-5.36][build-file-5.36]]
tar -xf file-5.36.tar.gz
echo '>>> Building file-5.36'
pushd 'file-5.36'

./configure --prefix=/tools
make
make install

popd
rm -rf 'file-5.36'
# build-file-5.36 ends here

# [[file:~/org/projects/ft_linux.org::build-findutils-4.6.0][build-findutils-4.6.0]]
tar -xf findutils-4.6.0.tar.gz
echo '>>> Building findutils-4.6.0'
pushd 'findutils-4.6.0'

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/tools
make
make install

popd
rm -rf 'findutils-4.6.0'
# build-findutils-4.6.0 ends here

# [[file:~/org/projects/ft_linux.org::build-gawk-4.2.1][build-gawk-4.2.1]]
tar -xf gawk-4.2.1.tar.xz
echo '>>> Building gawk-4.2.1'
pushd 'gawk-4.2.1'

./configure --prefix=/tools
make
make install

popd
rm -rf 'gawk-4.2.1'
# build-gawk-4.2.1 ends here

# [[file:~/org/projects/ft_linux.org::build-gettext-0.19.8.1][build-gettext-0.19.8.1]]
tar -xf gettext-0.19.8.1.tar.xz
echo '>>> Building gettext-0.19.8.1'
pushd 'gettext-0.19.8.1'

cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared

make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext

cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin

popd
rm -rf 'gettext-0.19.8.1'
# build-gettext-0.19.8.1 ends here

# [[file:~/org/projects/ft_linux.org::build-grep-3.3][build-grep-3.3]]
tar -xf grep-3.3.tar.xz
echo '>>> Building grep-3.3'
pushd 'grep-3.3'

./configure --prefix=/tools
make
make install

popd
rm -rf 'grep-3.3'
# build-grep-3.3 ends here

# [[file:~/org/projects/ft_linux.org::build-gzip-1.10][build-gzip-1.10]]
tar -xf gzip-1.10.tar.xz
echo '>>> Building gzip-1.10'
pushd 'gzip-1.10'

./configure --prefix=/tools
make
make install

popd
rm -rf 'gzip-1.10'
# build-gzip-1.10 ends here

# [[file:~/org/projects/ft_linux.org::build-make-4.2.1][build-make-4.2.1]]
tar -xf make-4.2.1.tar.bz2
echo '>>> Building make-4.2.1'
pushd 'make-4.2.1'

sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/tools --without-guile
make
make install

popd
rm -rf 'make-4.2.1'
# build-make-4.2.1 ends here

# [[file:~/org/projects/ft_linux.org::build-patch-2.7.6][build-patch-2.7.6]]
tar -xf patch-2.7.6.tar.xz
echo '>>> Building patch-2.7.6'
pushd 'patch-2.7.6'

./configure --prefix=/tools
make
make install

popd
rm -rf 'patch-2.7.6'
# build-patch-2.7.6 ends here

# [[file:~/org/projects/ft_linux.org::build-perl-5.28.1][build-perl-5.28.1]]
tar -xf perl-5.28.1.tar.xz
echo '>>> Building perl-5.28.1'
pushd 'perl-5.28.1'

sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth

make

cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.28.1
cp -Rv lib/* /tools/lib/perl5/5.28.1

popd
rm -rf 'perl-5.28.1'
# build-perl-5.28.1 ends here

# [[file:~/org/projects/ft_linux.org::build-Python-3.7.2][build-Python-3.7.2]]
tar -xf Python-3.7.2.tar.xz
echo '>>> Building Python-3.7.2'
pushd 'Python-3.7.2'

sed -i '/def add_multiarch_paths/a \        return' setup.py

./configure --prefix=/tools --without-ensurepip
make
make install

popd
rm -rf 'Python-3.7.2'
# build-Python-3.7.2 ends here

# [[file:~/org/projects/ft_linux.org::build-sed-4.7][build-sed-4.7]]
tar -xf sed-4.7.tar.xz
echo '>>> Building sed-4.7'
pushd 'sed-4.7'

./configure --prefix=/tools
make
make install

popd
rm -rf 'sed-4.7'
# build-sed-4.7 ends here

# [[file:~/org/projects/ft_linux.org::build-tar-1.31][build-tar-1.31]]
tar -xf tar-1.31.tar.xz
echo '>>> Building tar-1.31'
pushd 'tar-1.31'

./configure --prefix=/tools
make
make install

popd
rm -rf 'tar-1.31'
# build-tar-1.31 ends here

# [[file:~/org/projects/ft_linux.org::build-texinfo-6.5][build-texinfo-6.5]]
tar -xf texinfo-6.5.tar.xz
echo '>>> Building texinfo-6.5'
pushd 'texinfo-6.5'

./configure --prefix=/tools
make
make install

popd
rm -rf 'texinfo-6.5'
# build-texinfo-6.5 ends here

# [[file:~/org/projects/ft_linux.org::build-util-linux-2.33.1][build-util-linux-2.33.1]]
tar -xf util-linux-2.33.1.tar.xz
echo '>>> Building util-linux-2.33.1'
pushd 'util-linux-2.33.1'

./configure --prefix=/tools                \
            --without-python               \
            --disable-makeinstall-chown    \
            --without-systemdsystemunitdir \
            --without-ncurses              \
            PKG_CONFIG=""

make
make install

popd
rm -rf 'util-linux-2.33.1'
# build-util-linux-2.33.1 ends here

# [[file:~/org/projects/ft_linux.org::build-xz-5.2.4][build-xz-5.2.4]]
tar -xf xz-5.2.4.tar.xz
echo '>>> Building xz-5.2.4'
pushd 'xz-5.2.4'

./configure --prefix=/tools
make
make install

popd
rm -rf 'xz-5.2.4'
# build-xz-5.2.4 ends here
