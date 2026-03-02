#!/bin/bash
# vagrant-prepare.sh - Prepare image for Vagrant box conversion
# This script runs inside the VM during build to prepare it for Vagrant

set -e

echo "==> Preparing system for Vagrant..."

# Create vagrant user with password 'vagrant'
echo "Creating vagrant user..."
useradd -m -s /bin/bash vagrant || true
echo "vagrant:vagrant" | chpasswd

# Grant vagrant user passwordless sudo
echo "Configuring sudo for vagrant user..."
echo "vagrant ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vagrant
chmod 0440 /etc/sudoers.d/vagrant

# Install vagrant insecure public key for SSH
echo "Installing Vagrant insecure public key..."
mkdir -p /home/vagrant/.ssh
chmod 0700 /home/vagrant/.ssh

curl -sSL https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub \
    -o /home/vagrant/.ssh/authorized_keys || \
wget -q https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub \
    -O /home/vagrant/.ssh/authorized_keys

chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Configure SSH for Vagrant
echo "Configuring SSH..."
sed -i 's/^#*UseDNS.*/UseDNS no/' /etc/ssh/sshd_config
sed -i 's/^#*GSSAPIAuthentication.*/GSSAPIAuthentication no/' /etc/ssh/sshd_config

# Install VirtualBox Guest Additions if on VirtualBox
if lspci | grep -i virtualbox > /dev/null 2>&1; then
    echo "VirtualBox detected, installing Guest Additions..."
    dnf install -y kernel-devel kernel-headers gcc make perl bzip2 || true
    # Guest Additions ISO should be mounted by Packer
fi

# Install QEMU Guest Agent if on QEMU/KVM
if lspci | grep -i "Red Hat" > /dev/null 2>&1 || [ -d /sys/class/virtio-ports ]; then
    echo "QEMU/KVM detected, installing guest agent..."
    dnf install -y qemu-guest-agent || true
    systemctl enable qemu-guest-agent || true
fi

# Minimize disk space usage
echo "Minimizing disk space..."
dnf clean all

# Zero out free space to improve compression
echo "Zeroing free space (this may take a while)..."
dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null || true
rm -f /EMPTY

echo "==> Vagrant preparation complete!"
