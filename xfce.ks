# digitalr00ts xfce kickstart file
#platform=x86, AMD64, or Intel EM64T

text

%packages
# ### ### ###
# @^xfce-desktop-environment
# ### ### ###
# base-x
# standard
# core
# admin-tools
-@dial-up
# fonts
-input-methods
# multimedia
# networkmanager-submodules
-hardware-support
# printing
# guest-desktop-agents
# xfce-desktop

# ### ### ###
# @xfce-apps
# ### ### ###
catfish
-claws-mail
-claws-mail-plugins-archive
-claws-mail-plugins-att-remover
-claws-mail-plugins-attachwarner
-claws-mail-plugins-fetchinfo
-claws-mail-plugins-mailmbox
-claws-mail-plugins-newmail
-claws-mail-plugins-notification
-claws-mail-plugins-pgp
-claws-mail-plugins-rssyl
-claws-mail-plugins-smime
-claws-mail-plugins-spam-report
-claws-mail-plugins-tnef
-claws-mail-plugins-vcalendar
-evince
-galculator
-geany
gparted
-leafpad
-midori
-orage
pidgin
-ristretto
seahorse
transmission
xarchiver
xfce4-clipman-plugin
xfce4-dict-plugin

# ### ### ###
# @xfce-media
# ### ### ###
-asunder
-parole
pavucontrol
-pragha
-xfburn

# ### ### ###
light-locker
lightdm-gtk
lightdm-gtk-greeter-settings
xguest

%end

%post
curl --progress-bar --location --output atom.rpm https://atom.io/download/rpm
rpm --upgrade --verbose --hash atom.rpm
rm atom.x86_64.rpm
%end
