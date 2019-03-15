    pacman --noconfirm -Syu bison parted wget
    umount -R /mnt/lfs || true
    swapoff /dev/sdb2 || true
    parted -s /dev/sdb mklabel msdos
    parted -s /dev/sdb mkpart primary ext4 1MiB 1GiB
    parted -s /dev/sdb set 1 boot on
    parted -s /dev/sdb mkpart primary linux-swap 1GiB 3GiB
    parted -s /dev/sdb mkpart primary ext4 3GiB 100%
    mkfs.ext2 /dev/sdb1
    mkswap /dev/sdb2
    mkfs.ext4 /dev/sdb3
    mkdir -p /mnt/lfs
    mount /dev/sdb3 /mnt/lfs
    mkdir -p /mnt/lfs/boot
    mount /dev/sdb1 /mnt/lfs/boot
    swapon /dev/sdb2
