# Using Vagrant with Built Images

This guide explains how to use the Vagrantfiles included in this project with the Fedora images built by Packer.

## Prerequisites

1. **Vagrant**: Install Vagrant 2.3.0 or later
2. **vagrant-qemu plugin**: Required for QEMU/KVM support

```bash
# Install vagrant-qemu plugin
vagrant plugin install vagrant-qemu
```

1. **QEMU/KVM**: Ensure QEMU and KVM are installed on your system

```bash
# On Fedora/RHEL
sudo dnf install qemu-kvm libvirt

# Verify KVM is available
lsmod | grep kvm
```

## Available Vagrantfiles

### Vagrantfile (Server)

Optimized for headless server workloads:

- **Memory**: 2GB RAM
- **CPUs**: 2 cores
- **Display**: Headless (no GUI)
- **SSH Port**: 2222
- **Use Case**: Development servers, testing, CI/CD

### Vagrantfile.workstation

Optimized for desktop environments:

- **Memory**: 4GB RAM
- **CPUs**: 4 cores
- **Display**: GTK with OpenGL acceleration
- **SSH Port**: 2223
- **Use Case**: GUI applications, desktop testing

## Quick Start

### 1. Build the Images

First, build the Fedora images with Packer:

```bash
# Build server variant
make build-server-qemu

# Build workstation variant
make build-workstation-qemu
```

This creates:

- `output/vagrant/fedora-44-server-libvirt.box`
- `output/vagrant/fedora-44-workstation-libvirt.box`

### 2. Add Boxes to Vagrant

```bash
# Add server box
vagrant box add fedora-44-server output/vagrant/fedora-44-server-libvirt.box

# Add workstation box
vagrant box add fedora-44-workstation output/vagrant/fedora-44-workstation-libvirt.box

# Verify boxes are added
vagrant box list
```

### 3. Start the VM

#### Server Variant

```bash
# Use the default Vagrantfile
vagrant up --provider=qemu

# SSH into the VM
vagrant ssh

# Check status
vagrant status
```

#### Workstation Variant

```bash
# Use the workstation Vagrantfile
VAGRANT_VAGRANTFILE=Vagrantfile.workstation vagrant up --provider=qemu

# SSH into the VM
VAGRANT_VAGRANTFILE=Vagrantfile.workstation vagrant ssh

# The GUI should appear automatically
```

## Common Vagrant Commands

```bash
# Start the VM
vagrant up

# Stop the VM
vagrant halt

# Restart the VM
vagrant reload

# SSH into the VM
vagrant ssh

# Check VM status
vagrant status

# Destroy the VM
vagrant destroy

# Re-provision the VM
vagrant provision
```

## Customization

### Modify Resource Allocation

Edit the Vagrantfile to change memory or CPU:

```ruby
config.vm.provider "qemu" do |qemu, override|
  qemu.memory = 4096  # Change to 4GB
  qemu.cpus = 4       # Change to 4 CPUs
end
```

### Enable Port Forwarding

Uncomment or add port forwarding rules:

```ruby
# Forward host port 8080 to guest port 80
config.vm.network "forwarded_port", guest: 80, host: 8080

# Forward multiple ports
config.vm.network "forwarded_port", guest: 443, host: 8443
config.vm.network "forwarded_port", guest: 3000, host: 3000
```

### Enable Shared Folders

Mount local directories in the VM:

```ruby
# Mount current directory to /vagrant
config.vm.synced_folder ".", "/vagrant"

# Mount specific folders
config.vm.synced_folder "./data", "/data", create: true
```

### Add Provisioning

Add shell or Ansible provisioning:

```ruby
# Shell provisioning
config.vm.provision "shell", inline: <<-SHELL
  dnf install -y nginx
  systemctl enable --now nginx
SHELL

# Ansible provisioning
config.vm.provision "ansible" do |ansible|
  ansible.playbook = "ansible/playbook-server.yml"
  ansible.extra_vars = {
    fedora_version: "44"
  }
end
```

## Multiple VMs

Run both server and workstation simultaneously:

### Option 1: Separate Directories

```bash
# Create separate directories
mkdir server workstation

# Copy Vagrantfiles
cp Vagrantfile server/
cp Vagrantfile.workstation workstation/Vagrantfile

# Start each in its directory
cd server && vagrant up
cd workstation && vagrant up
```

### Option 2: Multi-Machine Vagrantfile

Create a custom Vagrantfile:

```ruby
Vagrant.configure("2") do |config|
  # Server VM
  config.vm.define "server" do |server|
    server.vm.box = "fedora-44-server"
    server.vm.hostname = "fedora-server"

    server.vm.provider "qemu" do |qemu|
      qemu.memory = 2048
      qemu.cpus = 2
      qemu.ssh_port = 2222
    end
  end

  # Workstation VM
  config.vm.define "workstation" do |ws|
    ws.vm.box = "fedora-44-workstation"
    ws.vm.hostname = "fedora-workstation"

    ws.vm.provider "qemu" do |qemu|
      qemu.memory = 4096
      qemu.cpus = 4
      qemu.ssh_port = 2223
      qemu.extra_qemu_args = ["-display", "gtk,gl=on"]
    end
  end
end
```

Then:

```bash
# Start specific VM
vagrant up server
vagrant up workstation

# SSH to specific VM
vagrant ssh server
vagrant ssh workstation
```

## Troubleshooting

### KVM Not Available

**Problem**: Error about KVM not being available

**Solution**:

```bash
# Check if KVM module is loaded
lsmod | grep kvm

# Load KVM module
sudo modprobe kvm
sudo modprobe kvm_intel  # For Intel CPUs
sudo modprobe kvm_amd    # For AMD CPUs

# Verify your user is in kvm/libvirt groups
groups
sudo usermod -a -G kvm,libvirt $USER
```

### SSH Timeout

**Problem**: Vagrant times out waiting for SSH

**Solution**:

- Check that the box was built correctly with Packer
- Verify SSH port is not already in use
- Increase SSH timeout in Vagrantfile:

```ruby
config.vm.boot_timeout = 600  # 10 minutes
```

### Display Issues (Workstation)

**Problem**: GUI doesn't appear for workstation

**Solution**:

- Ensure you're using the workstation Vagrantfile
- Check QEMU display arguments:

```ruby
qemu.extra_qemu_args = [
  "-enable-kvm",
  "-cpu", "host",
  "-vga", "virtio",
  "-display", "gtk,gl=on"
]
```

- Try alternative displays: `sdl`, `gtk`, `vnc`

### Box Already Exists

**Problem**: Box name already in use

**Solution**:

```bash
# Remove existing box
vagrant box remove fedora-44-server

# Re-add with new box
vagrant box add fedora-44-server output/vagrant/fedora-44-server-libvirt.box
```

## Running Ansible from Host

You can run Ansible playbooks from your host machine targeting the Vagrant VM,
which is useful for testing changes without rebuilding the box.

### Method 1: Using vagrant ssh-config

Generate SSH configuration and use it with Ansible:

```bash
# Start the VM
vagrant up

# Generate SSH config
vagrant ssh-config > vagrant-ssh-config

# Create an Ansible inventory file
cat > vagrant-inventory.ini << 'EOF'
[vagrant]
fedora-dev ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root

[vagrant:vars]
ansible_ssh_private_key_file=~/.vagrant.d/insecure_private_key
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# Run your playbook
ansible-playbook -i vagrant-inventory.ini ansible/playbook-server.yml \
  --extra-vars "fedora_version=44"
```

### Method 2: Using Password Authentication

If using the default password authentication:

```bash
# Create inventory with password
cat > vagrant-inventory.ini << 'EOF'
[vagrant]
fedora-dev ansible_host=127.0.0.1 ansible_port=2222 ansible_user=root ansible_password=packer

[vagrant:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

# Run playbook
ansible-playbook -i vagrant-inventory.ini ansible/playbook-server.yml
```

### Method 3: Dynamic Inventory Script

Create a dynamic inventory script for easier management:

```bash
#!/bin/bash
# vagrant-inventory.sh

cat << 'EOF'
{
  "vagrant": {
    "hosts": ["127.0.0.1"],
    "vars": {
      "ansible_port": 2222,
      "ansible_user": "root",
      "ansible_password": "packer",
      "ansible_ssh_common_args": "-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    }
  }
}
EOF
```

Make it executable and use it:

```bash
chmod +x vagrant-inventory.sh
ansible-playbook -i vagrant-inventory.sh ansible/playbook-server.yml
```

### Method 4: Using Vagrant's Ansible Inventory

Leverage Vagrant's built-in inventory:

```bash
# Get Vagrant's SSH details
vagrant ssh-config

# Use with Ansible directly
ansible all -i $(vagrant ssh-config | grep HostName | awk '{print $2}'), \
  -u root \
  --ssh-common-args="-p $(vagrant ssh-config | grep Port | awk '{print $2}') -o StrictHostKeyChecking=no" \
  -m ping
```

### Testing Ansible Collection Changes

Test local collection changes against the Vagrant VM:

```bash
# Start the VM
vagrant up

# Set local collections path and run playbook
ansible-playbook -i vagrant-inventory.ini \
  ansible/playbook-server.yml \
  -e "ansible_collections_path=/path/to/local/ansible-collection" \
  -e "fedora_version=44"
```

### Running Ad-Hoc Commands

Execute quick commands without a playbook:

```bash
# Check connectivity
ansible -i vagrant-inventory.ini vagrant -m ping

# Get facts
ansible -i vagrant-inventory.ini vagrant -m setup

# Run shell command
ansible -i vagrant-inventory.ini vagrant -m shell -a "dnf list installed"

# Install package
ansible -i vagrant-inventory.ini vagrant -m dnf -a "name=htop state=present"
```

### Using with Multiple VMs

For multi-machine setup, create a comprehensive inventory:

```ini
# multi-vagrant-inventory.ini
[servers]
fedora-server ansible_host=127.0.0.1 ansible_port=2222

[workstations]
fedora-workstation ansible_host=127.0.0.1 ansible_port=2223

[all:vars]
ansible_user=root
ansible_password=packer
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[all:children]
servers
workstations
```

Then target specific groups:

```bash
# Run on servers only
ansible-playbook -i multi-vagrant-inventory.ini ansible/playbook-server.yml \
  --limit servers

# Run on workstations only
ansible-playbook -i multi-vagrant-inventory.ini ansible/playbook-workstation.yml \
  --limit workstations

# Run on all
ansible-playbook -i multi-vagrant-inventory.ini site.yml
```

### Ansible Configuration

Create an `ansible.cfg` in your project root for Vagrant-specific settings:

```ini
[defaults]
inventory = vagrant-inventory.ini
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml

[ssh_connection]
ssh_args = -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null
pipelining = True
```

Then simply run:

```bash
ansible-playbook ansible/playbook-server.yml
```

## Security Notes

⚠️ **Important**: The default SSH credentials are:

- Username: `root`
- Password: `packer`

**These are for development only!** Before production use:

1. Change root password
2. Add SSH keys
3. Disable password authentication
4. Create non-root users

```bash
# Inside the VM
passwd root  # Change root password
useradd -m -G wheel myuser  # Create user with sudo access
passwd myuser
```

## References

- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [vagrant-qemu Plugin](https://github.com/ppggff/vagrant-qemu)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [Vagrantfile Configuration](https://www.vagrantup.com/docs/vagrantfile)
