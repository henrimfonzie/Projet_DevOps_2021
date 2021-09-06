# -*- mode: ruby -*-
# vi: set ft=ruby :

 Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/bionic64"
    config.vm.provision "shell", path: "install.sh"
 
    config.vm.provider "virtualbox" do |vb|
      vb.customize ["modifyvm", :id, "--audio", "none"] # desactiver carte son. cause bloquage dans le provisioning.
      vb.memory = 4048
      vb.cpus = 4
      vb.name = "vm-filrouge-projet"
    end
 
  config.vm.network "private_network", ip: "192.168.0.200"
  #config.vm.network "public_network"
  config.vm.synced_folder "project/", "/home/project", create: true
end