Vagrant.configure("2") do |config|
  config.vm.box = "generic/alpine38"
  config.vm.provider "virtualbox" do |vbox|
    vbox.memory = 4096
    vbox.cpus = 4
    lfs_disk = "/home/dkrm/dev/ft_linux/lfs.vdi"
    
    if not File.exists?(lfs_disk)
      vbox.customize ['createmedium',
                      '--filename', lfs_disk,
                      '--variant', 'Fixed',
                      '--size', 20 * 1024]
    end 
    
    if not File.exist?(".vagrant/machines/default/virtualbox/action_provision")
      vbox.customize ['storagectl', :id,
                      '--name', 'SATA Controller',
                      '--add', 'sata',
                      '--portcount', 2]
    end
    
    vbox.customize ['storageattach', :id,
                    '--storagectl', 'SATA Controller',
                    '--port', 1,
                    '--device', 0,
                    '--type', 'hdd',
                    '--medium', lfs_disk]
  end
  config.vm.provision "10-partition", type: :shell, path: "10-partition.sh"
  config.vm.provision "20-setup"    , type: :shell, path: "20-setup.sh"
end
