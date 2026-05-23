# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile for Fedora images built with Packer
# Uses vagrant-qemu provider for QEMU/KVM acceleration

Vagrant.configure("2") do |config|
  # Box configuration - update with your built box
  # Example: vagrant box add fedora-44-server output/vagrant/fedora-44-server-libvirt.box
  config.vm.box = "fedora-44-server"

  # Hostname
  config.vm.hostname = "fedora-dev"

  # Network configuration
  # Private network with DHCP
  config.vm.network "private_network", type: "dhcp"

  # Port forwarding examples (uncomment as needed)
  # config.vm.network "forwarded_port", guest: 80, host: 8080
  # config.vm.network "forwarded_port", guest: 443, host: 8443

  # Synced folder configuration
  # Disable default /vagrant share if not needed
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Optional: Mount specific folders
  # config.vm.synced_folder "./shared", "/home/vagrant/shared", create: true

  # QEMU Provider Configuration
  config.vm.provider "qemu" do |qemu, override|
    # Memory allocation (in MB)
    qemu.memory = 2048

    # CPU allocation
    qemu.cpus = 2

    # CPU architecture
    qemu.arch = "x86_64"

    # Machine type
    qemu.machine = "q35"

    # Enable KVM acceleration (requires KVM support on host)
    qemu.qemu_dir = "/usr/bin"

    # Additional QEMU arguments
    qemu.extra_qemu_args = [
      "-enable-kvm",
      "-cpu", "host"
    ]

    # SSH configuration
    qemu.ssh_port = 2222
    override.ssh.username = "root"
    override.ssh.password = "packer"  # Change this in production!

    # Network configuration for QEMU
    qemu.net_device = "virtio-net-pci"
  end

  # Provisioning - run after VM is up
  config.vm.provision "shell", inline: <<-SHELL
    echo "Fedora VM provisioned successfully!"
    echo "Hostname: $(hostname)"
    echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)"
    echo "Kernel: $(uname -r)"
  SHELL

  # Optional: Ansible provisioning
  # config.vm.provision "ansible" do |ansible|
  #   ansible.playbook = "ansible/playbook-server.yml"
  #   ansible.extra_vars = {
  #     fedora_version: "44"
  #   }
  # end
end
