# gui/base-x.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Base-X
# Description: Local X.org display server

%packages

glx-utils
mesa-dri-drivers
-plymouth-system-theme
#xorg-x11-drv-armsoc
#xorg-x11-drv-ati
#xorg-x11-drv-evdev
xorg-x11-drv-fbdev
#xorg-x11-drv-freedreno
#xorg-x11-drv-intel
xorg-x11-drv-libinput
#xorg-x11-drv-nouveau
#xorg-x11-drv-omap
#xorg-x11-drv-openchrome
#xorg-x11-drv-qxl
#xorg-x11-drv-vesa
#xorg-x11-drv-vmware
#xorg-x11-drv-wacom
xorg-x11-server-Xorg
xorg-x11-utils
xorg-x11-xauth
xorg-x11-xinit

# Optional
#xorg-x11-drv-geode

%end

