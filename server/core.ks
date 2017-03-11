# server/core.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Fedora Server product core
# Description: Packages mandatory for the server product.

%packages
# Mandatory

chrony
#fedora-release-server
PackageKit
polkit
realmd
timedatex

# Default
dhcp-client
NetworkManager-team
%end

