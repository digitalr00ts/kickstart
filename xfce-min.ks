# digitalr00ts xfce-min kickstart file
#platform=x86, AMD64, or Intel EM64T

%include x-base.ks

%packages
# ### ### ###
# @xfce-desktop
# ### ### ###
-NetworkManager-l2tp
-NetworkManager-openconnect
NetworkManager-openvpn
NetworkManager-pptp
NetworkManager-vpnc
NetworkManager-vpnc-gnome
-Thunar
-abrt-desktop
-adwaita-gtk2-theme
-adwaita-icon-theme
-albatross-gtk2-theme
-albatross-gtk3-theme
-albatross-xfwm4-theme
alsa-utils
-bluebird-gtk2-theme
-bluebird-gtk3-theme
-bluebird-xfwm4-theme
desktop-backgrounds-compat
-fedora-icon-theme
firewall-config
fros-recordmydesktop
greybird-gtk2-theme
greybird-gtk3-theme
greybird-xfce4-notifyd-theme
greybird-xfwm4-theme
gtk-xfce-engine
gvfs
gvfs-archive
-initial-setup-gui
-lightdm-gtk
network-manager-applet
nm-connection-editor
openssh-askpass
-rodent-icon-theme
-thunar-archive-plugin
-thunar-media-tags-plugin
-thunar-volman
-tumbler
xdg-user-dirs-gtk
-xfce4-about
xfce4-appfinder
xfce4-datetime-plugin
xfce4-panel
xfce4-places-plugin
xfce4-power-manager
xfce4-pulseaudio-plugin
xfce4-screenshooter-plugin
xfce4-session
xfce4-session-engines
xfce4-settings
xfce4-terminal
xfconf
-xfdesktop
xfwm4
xfwm4-theme-nodoka
xfwm4-themes
-xscreensaver-base
-yumex

# ### ### ###
# @xfce-extra-plugins
# ### ### ###
-xfce4-battery-plugin
-xfce4-cpugraph-plugin
-xfce4-diskperf-plugin
-xfce4-eyes-plugin
-xfce4-fsguard-plugin
-xfce4-genmon-plugin
xfce4-mailwatch-plugin
-xfce4-mount-plugin
-xfce4-netload-plugin
-xfce4-sensors-plugin
-xfce4-systemload-plugin
xfce4-taskmanager
-xfce4-time-out-plugin
-xfce4-verve-plugin
-xfce4-weather-plugin
-xfce4-websearch-plugin
xfce4-whiskermenu-plugin
-xfce4-xkb-plugin
-xfdashboard
-xfdashboard-themes

# ### ### ###
gnome-disk-utility

bluecurve-cursor-theme
calendar
dnssec-trigger-panel
elementary-xfce-icon-theme
korora-settings-xfce
pcmanfm
%end

%post
#!/bin/bash
crudini --set --verbose /etc/xdg/libfm/libfm.conf config terminal xfce4-terminal
crudini --set --verbose /etc/xdg/libfm/libfm.conf config no_child_non_expandable 1
crudini --set --verbose /etc/xdg/libfm/libfm.conf ui shadow_hidden 1
crudini --set --verbose /etc/xdg/pcmanfm/default/pcmanfm.conf ui media_in_new_tab 1
crudini --set --verbose /etc/skel/.config/xfce4/terminal/terminalrc Configuration BackgroundMode ''
# xmlstarlet edit --update "//property[@name='IconThemeName']/@value" --value "elementary-xfce-darker" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
xmlstarlet edit --inplace --update "//property[@name='IconThemeName']/@value" --value "elementary-xfce-darker" /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
xmlstarlet edit --inplace --update "//property[@name='CursorThemeName']/@value" --value "Bluecurve" /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
echo "exec /usr/bin/xfce4-session" > /etc/skel/.xinitrc

users=$(ls -d1 /home/*/)
for folder in $users
do
  [ -f ${folder}.config/xfce4/terminal/terminalrc ] && cp /etc/skel/.config/xfce4/terminal/terminalrc ${folder}.config/xfce4/terminal/terminalrc
  [ -f ${folder}.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ] && cp /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml ${folder}.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
done
%end
