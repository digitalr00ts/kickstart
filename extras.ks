# digitalr00ts base kickstart file
#platform=x86, AMD64, or Intel EM64T

%packages
# ### ### ###
@virtualization-headless
# ### ### ###
# virt-install
# libvirt-daemon-config-network
# libvirt-daemon-kvm
# qemu-kvm
# Optional ### ### ###
# guestfs-browser
# libguestfs-tools
# python-libguestfs
virt-top

ksm
# libvirt-client
qemu-kvm-tools
tunctl

# container
docker
docker-compose
docker-selinux
# docker-distribution
# docker-forward-journald
# docker-logrotate
# docker-utils
docker-vim
sen
skopeo

# vagrant
vagrant
vagrant-adbinfo
vagrant-cachier
vagrant-hostmanager
vagrant-libvirt
vagrant-lxc
vagrant-registration

# Cockpit
cockpit
cockpit-bridge
cockpit-docker
cockpit-pcp
cockpit-shell
cockpit-storaged
cockpit-sosreport
cockpit-networkmanager
cockpit-ws

storaged
tuned
tuned-utils
pcp
%end

%post
# firewall-cmd --add-service=cockpit
%end
