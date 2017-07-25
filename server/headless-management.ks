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
# Fatal error on installation, disabling for now
# cockpit-pcp

# Not Included
# Anaconda throws error that is missing even though it is in comps-f26.xml
#docker-cockpit

%end

