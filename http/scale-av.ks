# Fedora Base Kickstart Configuration
# Minimal configuration for automated installation

url --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch

# Fedora repositories
repo --name=fedora --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name=updates --mirrorlist=https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

# Use text mode installation
text

# Accept EULA
eula --agreed

# System language
lang en_US.UTF-8

# Keyboard layout
keyboard --vckeymap=us --xlayouts='us'

# System timezone
timezone America/Los_Angeles --utc

# Network configuration
network --bootproto=dhcp --device=link --activate --onboot=yes --hostname=scale.local
	
# Services enabled	
services --enabled=sshd,NetworkManager,chronyd
	
# Setup users
rootpw --lock --iscrypted locked
user --iscrypted --name admin --password $6$rounds=123456$kickstart$8BDRblt8lkOOA..4iCG/xJZR6L4nl2ZJxsZ9pkoK1ECbfqkZs60Gew6j2jvVCYSi9.e.hYGK2.S1v4ZG6zpBT/ --gecos Administrator --groups wheel
user --iscrypted --name vagrant --password $6$rounds=5000$default$L/jbIehFuDL9yFtCbhxk/DrduO/YwFORc8a3AT4.wx3WIFUeMHOS/ihM8uV7Ovi4p571WPJq70t0XJbAwBH83/ --gecos Vagrant --uid 900 --gid 900 --groups wheel
user --iscrypted --name scaleav --password $6$rounds=10000$1337linux$0zb4FkOf6NMZoEvHkeRQDYMiG.2RwgfFbZC75GJ2bxKJ6i6OgDSDbtOApNWHcxPU3NXfqHXKYNFbG0EqtcBAL. --gecos 'SCaLE AV' --uid 2000 --gid 2000

# System authorization
authselect select minimal

# SELinux configuration
selinux --enforcing

# Firewall configuration
firewall --enabled --service=ssh --service=mdns

# Bootloader
bootloader --timeout=5

# Clear the Master Boot Record
zerombr

# Clear all partitions
clearpart --all --initlabel --disklabel=msdos

# Automatic partitioning
autopart --type=btrfs

# Reboot after installation
reboot

# Package selection - minimal install
%packages --exclude-weakdeps --ignoremissing

# from cosmic-desktop-environment

@admin-tools
@base-graphical
@core
@cosmic-desktop
@fonts
@hardware-support
@input-methods
@multimedia
@networkmanager-submodules
@standard

# from cosmic-desktop-app

# ark
# gnome-calculator
# gnome-disk-utility
# gnome-system-monitor

# custom

# @vlc
git
neovim
mpv
zsh

libva
libva-utils
libva-intel-media-driver
gstreamer1-vaapi
mesa-dri-drivers
ffmpeg-free

# Fix Intel Video Acceleration
# intel-media-driver
# ffmpeg
# intel-gpu-tools

-plymouth
-plymouth-system-theme
-plymouth-theme-spinner
-plymouth-scripts
-plymouth-plugin-twos-step
-cosmic-store

%end

# Post-installation script
%post --erroronfail --log=/root/ks-post.log

# Install RPM Fusion repositories
echo "Installing RPM Fusion repositories..."
dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Install RPM Fusion packages
echo "Installing multimedia and codec packages..."
dnf install -y \
    ffmpeg \
    intel-media-driver \
    intel-gpu-tools

# Give Vagrant user permission to sudo w/o password.
printf -- 'Defaults:vagrant !requiretty\n%%vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant
chmod 440 /etc/sudoers.d/vagrant

# Set Python3 as default python (needed for Ansible)
# alternatives --set python /usr/bin/python3

# Clean up machine-specific data to ensure uniqueness on first boot
rm -f /var/lib/systemd/random-seed
rm -f /etc/machine-id
touch /etc/machine-id

# Configure dnf
cat >> /etc/dnf/dnf.conf <<EOF
install_weak_deps=False
fastestmirror=True
repo_gpgcheck=True
timeout=10
EOF

# Clean DNF cache to save space
dnf clean all

truncate -c -s 0 /var/log/dnf.log
truncate -c -s 0 /var/log/dnf.librepo.log
truncate -c -s 0 /var/log/dnf.rpm.log
echo "Packages within this image:"
echo "-----------------------------------------------------------------------"
rpm -qa
echo "-----------------------------------------------------------------------"
rm -f /var/lib/rpm/__db*

journalctl --vacuum-time=1s

# Clean temporary files
rm -rf /tmp/*
rm -rf /var/tmp/*

# Log completion
echo "Kickstart post-installation complete - system ready for Ansible provisioning"
%end
