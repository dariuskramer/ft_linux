#!/usr/bin/env sh

set -e

source ~/.bash_profile
echo "ID => $(id)"
echo "LFS_TGT: $LFS_TGT"
cd /mnt/lfs/src


# Binutils
cd binutils-2.30
mkdir -v build && cd build
mkdir -v /tools/lib && ln -sv lib /tools/lib64
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make && make install
cd $LFS/src
rm -rf binutils-2.30


# GCC
cd gcc-7.3.0
tar -xf ../mpfr-4.0.1.tar.xz
mv -v mpfr-4.0.1 mpfr
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
sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64
mkdir -v build && cd build
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
make && make install
cd $LFS/src
rm -rf gcc-7.3.0


# Linux Header
cd linux-4.15.3
make mrproper
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include
cd $LFS/src
rm -rf linux-4.15.3


# Glibc
cd glibc-2.27
mkdir -v build && cd build
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2             \
      --with-headers=/tools/include      \
      libc_cv_forced_unwind=yes          \
      libc_cv_c_cleanup=yes
make && make install
cd $LFS/src
rm -rf glibc-2.27


# Libstdc++
tar xvf gcc-7.3.0.tar.xz
cd gcc-7.3.0
mkdir -v build && cd build
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/7.3.0
make && make install
cd $LFS/src
rm -rf gcc-7.3.0
