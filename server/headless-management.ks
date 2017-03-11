# server/core.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Headless Management
# Description: Tools for managing the system without an attached graphical console.

%packages

# Mandatory
cockpit-bridge
cockpit-networkmanager
cockpit-shell
cockpit-storaged
cockpit-ws
openssh-server
PackageKit
rolekit

# Optional
#cockpit-kubernetes
cockpit-pcp

# Not Included
docker-cockpit

%end

