# server/virtualization.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Virtualization
# Description: These packages provide a graphical virtualization environment.

%packages

# Mandatory
#virt-install
#libvirt-daemon-config-network
#libvirt-daemon-kvm

# Default
#qemu-kvm
virt-manager
virt-viewer

# Optional
#guestfs-browser
#libguestfs-tools
#python-libguestfs
#virt-top

%end

