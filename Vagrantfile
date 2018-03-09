# -*- mode: ruby -*-
# vi: set ft=ruby :

# https://github.com/kusnier/vagrant-persistent-storage
# $> vagrant plugin install vagrant-persistent-storage

disk_lfs = '/Volumes/Storage/goinfre/djean/ft_linux_lfs.vdi'

Vagrant.configure("2") do |config|
  config.vm.box = "archlinux/archlinux"

  config.vm.provider "virtualbox" do |v|
	  v.memory = 1024
	  v.cpus = 2
  end


  config.persistent_storage.use_lvm = false
  config.persistent_storage.enabled = true
  config.persistent_storage.location = "/Volumes/Storage/goinfre/djean/ft_linux_lfs.vdi"
  config.persistent_storage.size = 100 * 1024
  config.persistent_storage.mountname = 'lfs'
  config.persistent_storage.filesystem = 'ext4'
  config.persistent_storage.mountpoint = '/mnt/lfs'
  config.persistent_storage.volgroupname = 'lfs'

  config.vm.provision "shell", inline: <<-SHELL
	pacman --noconfirm -Syu bison
  SHELL
end
