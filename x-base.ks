# digitalr00ts base-x kickstart file
#platform=x86, AMD64, or Intel EM64T

xconfig

%packages
# ### ### ###
# @admin-tools
# ### ### ###
-abrt-desktop
authconfig-gtk
-fros-recordmydesktop
-gnome-disk-utility
-recordmydesktop
setroubleshoot
system-config-date
system-config-keyboard
system-config-language
system-config-users

policycoreutils
setools
system-config-audit
system-config-network
system-config-printer-applet
system-config-services
system-config-samba

# ### ### ###
# @base-x
# ### ### ###
glx-utils
mesa-dri-drivers
-plymouth-system-theme
-xorg-x11-drv-armsoc
-xorg-x11-drv-ati
xorg-x11-drv-evdev
xorg-x11-drv-fbdev
-xorg-x11-drv-freedreno
-xorg-x11-drv-geode
#xorg-x11-drv-intel
-xorg-x11-drv-mga
xorg-x11-drv-modesetting
#xorg-x11-drv-nouveau
-xorg-x11-drv-omap
-xorg-x11-drv-openchrome
-xorg-x11-drv-qxl
#xorg-x11-drv-synaptics
xorg-x11-drv-vesa
-xorg-x11-drv-vmmouse
-xorg-x11-drv-vmware
-xorg-x11-drv-wacom
xorg-x11-server-Xorg
xorg-x11-utils
xorg-x11-xauth
xorg-x11-xinit

# ### ### ###
# @basic-desktop
# ### ### ###
# adwaita-gtk2-theme
# adwaita-icon-theme
# awesome
# dwm
# fedora-icon-theme
# i3
# initial-setup-gui
# lightdm
# metacity
# openbox
# ratpoison
# xmonad-basic

# ### ### ###
# @networkmanager-submodules
# ### ### ###
NetworkManager-bluetooth
NetworkManager-wifi
-NetworkManager-wwan

# ### ### ###
# @printing
# ### ### ###
system-config-printer-udev
# Conditional Packages
system-config-printer

# @input-methods
# @hardware-support

-PackageKit*

#-korora-release-workstation
#adobe-release
#google-chrome-release
#google-earth-release
#google-talkplugin-release
#intellinuxgraphics-repo

libva
libva-utils
libva-vdpau-driver
%end

# %include base.cfg

%post

# make home dir - NOTE this seems to cause trouble on non-English installs :-(
#mkdir /etc/skel/{Documents,Downloads,Music,Pictures,Videos}
mkdir /etc/skel/Desktop

#systemctl set-default graphical.target
%end
