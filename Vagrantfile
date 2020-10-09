# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.trigger.before :provision do |trigger|
    trigger.name = "Clean up"
    trigger.info = "Deleting previous images and boxes."
    trigger.run  = {path: "scripts/reset-images.sh"}
  end

  config.vm.box = "file://output/boxes/fedora32_libvirt.box"

  #shitty workaround for now
  config.ssh.insert_key = false

  # config.vm.box_check_update = false

  #config.vm.network "forwarded_port", guest: 22, host: 2222, host_ip: "127.0.0.1", id: 'ssh'

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine and only allow access
  # via 127.0.0.1 to disable public access
  # config.vm.network "forwarded_port", guest: 80, host: 8080, host_ip: "127.0.0.1"

  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.cpus = 2
    # libvirt.cputopology :sockets => '2', :cores => '2', :threads => '2'
    libvirt.memory = 1024
    libvirt.video_type = "qxl"
    libvirt.graphics_type = "spice"
    libvirt.input :type => "keyboard", :bus => "usb"
    libvirt.input :type => "mouse", :bus => "usb"
    libvirt.input :type => "tablet", :bus => "usb"
  end

  config.vm.provision "ansible" do |ansible|
    ansible.host_key_checking = false
    ansible.playbook = "playbooks/vagrant-up.yml"
  end

end
