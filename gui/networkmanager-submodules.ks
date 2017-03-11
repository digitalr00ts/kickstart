# gui/networkmanager-submodules.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Common NetworkManager Submodules
# Description: This group contains NetworkManager submodules that are commonly used, but may not be wanted in some streamlined configurations.

%packages

# Default
NetworkManager-bluetooth
NetworkManager-wifi
#NetworkManager-wwan

%end

