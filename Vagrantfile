# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
 config.vm.box = "centos/7"
   config.vm.define "k8smaster.example.com" do |s|
   s.vm.provider "libvirt" do |v| 
   v.storage :file, :size => '20G'
    v.memory = 2048
    v.cpus = 2
    end
  s.vm.network "private_network", ip: "192.168.121.8"
  s.vm.synced_folder ".", "/vagrant", disabled: true
  s.vm.synced_folder "scripts/k8smaster.example.com", "/usr/local/scripts", type: "rsync", owner: "root", group: "root"
  s.vm.provision "shell", inline: <<-SHELL
   chmod u+x /usr/local/scripts/k8smaster.sh
   /usr/local/scripts/k8smaster.sh
  SHELL
 end
 config.vm.define "node01.example.com" do |a|
    a.vm.provider "libvirt" do |v|
    v.storage :file, :size => '20G'
    v.memory = 2048
    v.cpus = 1
  end
  a.vm.network "private_network", ip: "192.168.121.9"
  a.vm.synced_folder ".", "/vagrant", disabled: true
  a.vm.synced_folder "scripts/node01.example.com", "/usr/local/scripts", type: "rsync", owner: "root", group: "root"
  a.vm.provision "shell", inline: <<-SHELL
   chmod u+x /usr/local/scripts/node01.sh
   /usr/local/scripts/node01.sh
  SHELL
  end
  
 config.vm.define "node02.example.com" do |b|
    b.vm.provider "libvirt" do |v|
    v.storage :file, :size => '20G'
    v.memory = 2048
    v.cpus = 1
  end
  b.vm.network "private_network", ip: "192.168.121.10"
  b.vm.synced_folder ".", "/vagrant", disabled: true
  b.vm.synced_folder "scripts/node02.example.com", "/usr/local/scripts", type: "rsync", owner: "root", group: "root"
  b.vm.provision "shell", inline: <<-SHELL
   chmod u+x /usr/local/scripts/node02.sh
   /usr/local/scripts/node02.sh
  SHELL
  end
end
