unless Vagrant.has_plugin?('vagrant-libvirt')
  puts 'vagrant-libvirt plugin not found, installing'
  system 'vagrant plugin install vagrant-libvirt'
  exec "vagrant #{ARGV.join(' ')}"
end

unless Vagrant.has_plugin?('vagrant-mutate')
  puts 'vagrant-mutate plugin not found, installing'
  system 'vagrant plugin install vagrant-mutate'
  exec "vagrant #{ARGV.join(' ')}"
end

unless Vagrant.has_plugin?('vagrant-reload')
  puts 'vagrant-reload plugin not found, installing'
  system 'vagrant plugin install vagrant-reload'
  exec "vagrant #{ARGV.join(' ')}"
end

Vagrant.configure("2") do |config|
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
