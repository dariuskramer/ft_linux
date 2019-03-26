Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-libvirt", "vagrant-reload"]
  config.vm.box = 'archlinux/archlinux'
  config.vm.provider :libvirt do |domain|
    domain.memory = 4096
    domain.cpus = 4
    domain.storage_pool_name = 'default'
    domain.storage :file,
                   :path => 'lfs_disk',
                   :device => 'vdb',
                   :size => '20G',
                   :allow_existing => true
  end
  config.vm.provision '00-version-check', type: :shell, path: '00-version-check.sh'
  config.vm.provision :reload
  config.vm.provision '10-setup-disk',    type: :shell, path: '10-setup-disk.sh'
end
