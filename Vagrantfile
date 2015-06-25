# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  config.vm.define "demo" do |demo|

    # Box template to use

    #Use this box if you want tp provision the box using the build script
    #demo.vm.box = "ubuntu/trusty64"

    # Use this box in the tutorial or if you've built it yourself
    demo.vm.box = "build/packer/ubuntu-14.04/ubuntu-14-04-x64-virtualbox-dpc15.box"

    # Increase memory available
    demo.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end

    demo.vm.network "private_network", ip: "10.0.4.56"

    # Windows Users - use this rather than NFS
    # demo.vm.synced_folder ".", "/vagrant", type: "nfs"

    demo.vm.synced_folder ".", "/vagrant", type: "nfs"

    demo.ssh.forward_agent = true

    # Install the hostsupdater plugin for easier host file editing
    #demo.hostsupdater.aliases = ["web.logstashdemo.com", "logs.logstashdemo.com", "elastic.logstashdemo.com"]

    # Use in conjuntion with the ubuntu/trusty64 base box if you don't have the
    # pre built tutorial box.
    #demo.vm.provision "shell", path: "build/bootstrap.sh"
  end
end
