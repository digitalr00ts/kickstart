# server/virtualization-headless.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Headless Virtualization
# Description: These packages provide a headless virtualization environment.

%packages

# Mandatory
virt-install
libvirt-daemon-config-network
libvirt-daemon-kvm

# Default
qemu-kvm
systemd-container

# Optional
guestfs-browser
libguestfs-tools
python-libguestfs
virt-top

%end

