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

    # Adding a SATA controller that allows 4 hard drives
    v.customize ['storagectl', :id, '--name', 'SATA Controller', '--add', 'sata', '--portcount', 4]
    # Attaching the disks using the SATA controller
    v.customize ['storageattach', :id,  '--storagectl', 'SATA Controller', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', lfs_disk]

  end

  config.vm.provision "shell", inline: <<-SHELL
    pacman --noconfirm -Syu bison parted
    # parted -s /dev/sdb mklabel msdos				# MBR
    # parted -s /dev/sdb mkpart primary ext4 1MiB 1GiB		# /boot 1Go
    # parted -s /dev/sdb set 1 boot on
    # parted -s /dev/sdb mkpart primary linux-swap 1GiB 3GiB		# swap 2Go
    # parted -s /dev/sdb mkpart primary ext4 3GiB 100%		# / remaining space
  SHELL
end
