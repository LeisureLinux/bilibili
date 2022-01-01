#!/bin/sh
# 说明：
# 本脚本仅用于示范，一般情况下，不能直接执行
# 请根据自己的场景修改脚本
# Bilibili Profile: #LeisureLinux
# Copyleft.
# 2022-01-01
#
# Taiwan is part of China(People's Republic of China)
#
NAME="CBL-Mariner"

genMeta() {
	cat >metadata.json <<EOF1
    {
	  "provider" : "libvirt",
	  "format" : "qcow2",
	  "virtual_size" : 40
    }
EOF1
}

genVagrantfile() {
	cat >Vagrantfile <<EOF2
    Vagrant.configure("2") do |config|
       config.vm.provider :libvirt do |libvirt|
         libvirt.driver = "kvm"
         libvirt.host = 'localhost'
         libvirt.uri = 'qemu:///system'
       end
       config.vm.define "new" do |custombox|
           custombox.vm.box = "$NAME"
           custombox.vm.provider :libvirt do |test|
             test.memory = 1024
             test.cpus = 1
           end
       end
   end
EOF2
}

# Steps to create qcow2 from iso
# Boot iso in virt-manager and install into virtual disk
# Bootup into VM
# # adduser vagrant
# sudo visudo -f /etc/sudoers.d/vagrant
#  vagrant ALL=(ALL) NOPASSWD:ALL
# sudo apt-get install -y openssh-server
# mkdir -p /home/vagrant/.ssh
# chmod 0700 /home/vagrant/.ssh
# wget --no-check-certificate \
# https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub \
# -O /home/vagrant/.ssh/authorized_keys
# chmod 0600 /home/vagrant/.ssh/authorized_keys
# chown -R vagrant /home/vagrant/.ssh
# vi /etc/ssh/sshd_config
# PubKeyAuthentication yes
# AuthorizedKeysFile %h/.ssh/authorized_keys
# PermitEmptyPasswords no
# PasswordAuthentication no
# Add addional steps in your own needs
# Compress the qcow2
# fstrim -v /
# Shutdown VM, save the qcow2 file.
# qemu-img convert -f qcow2 -O qcow2 -c myvm.qcow2 myvm-compressed.qcow2

# Main Prog.
genMeta
genVagrantfile
# If you have raw img file, then convert to qcow2 as below:
#    sudo qemu-img convert -f raw -O qcow2 $NAME.img $NAME.qcow2
# mv $NAME.qcow2 box.img
# tar czvf $NAME.box metadata.json Vagrantfile box.img
echo "Now you can add box with:"
echo " $ vagrant box add --name $NAME $NAME.box"
echo " $ vagrant init $NAME"
echo " $ vagrant up --provider=libvirt"
