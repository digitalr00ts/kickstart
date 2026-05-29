#!/bin/bash
# Kiwi NG Configuration Script
# Equivalent to kickstart %post section
# This runs inside the image during build

set -euxo pipefail

echo "========================================="
echo "Kiwi NG Configuration Script Starting"
echo "========================================="

#======================================
# Configure sudo for vagrant user
#======================================
echo "Configuring sudo for vagrant user..."
cat > /etc/sudoers.d/vagrant <<EOF
Defaults:vagrant !requiretty
%vagrant ALL=(ALL) NOPASSWD: ALL
EOF
chmod 440 /etc/sudoers.d/vagrant

#======================================
# Lock root password (security)
#======================================
echo "Locking root password..."
passwd -l root || true

#======================================
# Configure DNF for optimized performance
#======================================
echo "Configuring DNF..."
cat >> /etc/dnf/dnf.conf <<EOF

# Optimizations from kickstart
install_weak_deps=False
fastestmirror=True
repo_gpgcheck=True
timeout=10
max_parallel_downloads=8
EOF

#======================================
# Clean machine-specific data
# Ensures uniqueness on first boot
#======================================
echo "Cleaning machine-specific data..."
rm -f /var/lib/systemd/random-seed
rm -f /etc/machine-id
touch /etc/machine-id

#======================================
# Enable required services
#======================================
echo "Enabling services..."
systemctl enable sshd
systemctl enable NetworkManager

#======================================
# Configure firewall
#======================================
echo "Configuring firewall..."
systemctl enable firewalld
# Firewall rules will be applied on first boot

#======================================
# SELinux enforcing (already set by default)
#======================================
echo "Verifying SELinux is enforcing..."
if [ -f /etc/selinux/config ]; then
    sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
fi

#======================================
# Clean DNF cache and logs
#======================================
echo "Cleaning DNF cache..."
dnf clean all

truncate -c -s 0 /var/log/dnf.log || true
truncate -c -s 0 /var/log/dnf.librepo.log || true
truncate -c -s 0 /var/log/dnf.rpm.log || true

#======================================
# Display installed packages
#======================================
echo "========================================="
echo "Packages within this image:"
echo "========================================="
rpm -qa | sort

#======================================
# Clean RPM database
#======================================
echo "Cleaning RPM database..."
rm -f /var/lib/rpm/__db* || true

#======================================
# Clean systemd journal
#======================================
echo "Cleaning systemd journal..."
journalctl --vacuum-time=1s || true

#======================================
# Clean temporary files
#======================================
echo "Cleaning temporary files..."
rm -rf /tmp/* || true
rm -rf /var/tmp/* || true

#======================================
# Remove build logs
#======================================
rm -f /root/ks-post.log || true

echo "========================================="
echo "Kiwi NG Configuration Script Complete"
echo "System ready for Ansible provisioning"
echo "========================================="

exit 0
