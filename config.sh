#!/bin/bash

# GRUB configuration
sed -i 's/rhgb\|quiet//g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# Install utilities
dnf --assumeyes install crudini xmlstarlet

# PCManFM settings
crudini --set --verbose /etc/xdg/libfm/libfm.conf config terminal xfce4-terminal
crudini --set --verbose /etc/xdg/libfm/libfm.conf config no_child_non_expandable 1
crudini --set --verbose /etc/xdg/libfm/libfm.conf ui shadow_hidden 1
crudini --set --verbose /etc/xdg/pcmanfm/default/pcmanfm.conf ui media_in_new_tab 1

# xfce4-terminal settings
crudini --set --verbose /etc/skel/.config/xfce4/terminal/terminalrc Configuration BackgroundMode ''
crudini --set --verbose /home/default_admin/.config/xfce4/terminal/terminalrc Configuration BackgroundMode ''

# xfce4 icons theme
# xmlstarlet edit --update "//property[@name='IconThemeName']/@value" --value "elementary-xfce-darker" /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
xmlstarlet edit --inplace --update "//property[@name='IconThemeName']/@value" --value "elementary-xfce-darker" /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
xmlstarlet edit --inplace --update "//property[@name='IconThemeName']/@value" --value "elementary-xfce-darker" /home/default_admin/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml

# startx rc file
# echo "exec /usr/bin/xfce4-session" > /etc/skel/.xinitrc

cp 
