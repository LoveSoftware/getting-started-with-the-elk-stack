# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure("2") do |config|

  config.vm.define "demo" do |demo|

    # Box template to use
    demo.vm.box = "ubuntu/trusty64"

    # Increase memory available
    demo.vm.provider "virtualbox" do |v|
      v.memory = 2048
    end

    demo.vm.network "private_network", ip: "10.0.4.56"

    demo.vm.synced_folder ".", "/vagrant", type: "nfs"

    demo.ssh.forward_agent = true

    demo.hostsupdater.aliases = ["web.logstashdemo.com", "logs.logstashdemo.com", "elastic.logstashdemo.com"]

    demo.vm.provision "shell", path: "build/bootstrap.sh"
  end
end
