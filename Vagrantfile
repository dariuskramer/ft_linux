Vagrant.configure("2") do |config|
  config.vagrant.plugins = ["vagrant-libvirt"]
  config.vm.box = 'lfs/archlinux'
  config.vm.synced_folder ".", "/vagrant", type: "nfs", disabled: true
  config.vm.provider :libvirt do |domain|
    domain.memory = 4096
    domain.cpus = 8
    domain.storage :file,
                   :path => 'lfs_disk',
                   :device => 'vdb',
                   :size => '20G'
  end
  config.vm.provision '10-setup-disk',         type: :shell, path: '10-setup-disk.sh'
  config.vm.provision '20-setup-temp-system',  type: :shell, path: '20-setup-temp-system.sh'
  config.vm.provision '30-build-temp-system',  type: :shell, path: '30-build-temp-system.sh',
                      privileged: false,
                      env: { :BASH_ENV => "~/.bashrc" }
  
  config.vm.provision '40-setup-final-system', type: :shell, path: '40-setup-final-system.sh'
  
  config.vm.provision '50-setup-final-system', type: :file,
                      source: "50-setup-final-system.sh",
                      destination: "/mnt/lfs/sources/"
  config.vm.provision '50-exec-in-chroot',     type: :shell, path: 'xx-exec-in-chroot.sh',
                      args: ["/sources/50-setup-final-system.sh"]
end
