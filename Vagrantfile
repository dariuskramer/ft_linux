# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "archlinux/archlinux"

  lfs_disk = "/Volumes/Storage/goinfre/djean/ft_linux_lfs.vdi"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    
    # Building disk file if it doesn't exist
    if not File.exists?(lfs_disk)
      v.customize ['createmedium', '--filename', lfs_disk, '--variant', 'Standard', '--size', 100 * 1024]
    end 

    # Adding a SATA controller that allows 2 hard drives only if not yet provisioned
    if not File.exist?(".vagrant/machines/default/virtualbox/action_provision")
      v.customize ['storagectl', :id, '--name', 'SATA Controller', '--add', 'sata', '--portcount', 4]
    end

    # Attaching the disks using the SATA controller
    v.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', lfs_disk]

  end

  config.vm.provision "partition", type: :shell, inline: <<-SHELL
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
  SHELL

  config.vm.provision "setup", type: :shell, path: "setup.sh"
end
