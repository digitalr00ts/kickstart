#version=F25
#platform=x86, AMD64, or Intel EM64T
# digitalr00ts base kickstart file

%packages
# ### ### ###
# @core
# ### ### ###
# ------
# default
# ------
authconfig
dnf-plugins-core
dracut-config-rescue
firewalld
NetworkManager
# ppc64-utils
# ------
# optional
# ------
# dracut-config-generic
# initial-setup
# uboot-images-armv7
# uboot-tools

# ### ### ###
# @standard
# ### ### ###
# abrt-cli
acl
at
attr
bash-completion
# bc
bind-utils
bridge-utils
-btrfs-progs
bzip2
cifs-utils
coolkey
# cpio
crontabs
cryptsetup
# cyrus-sasl-plain
dbus
deltarpm
dos2unix
dosfstools
-ed
ethtool
-fedora-release-notes
file
-fpaste
-fprintd-pam
gnupg2
hunspell
iptstate
irqbalance
jwhois
logrotate
lsof
mailcap
man-pages
mcelog
-mdadm
microcode_ctl
mlocate
mtr
-nano
net-tools
nfs-utils
nmap-ncat
-ntfs-3g
-ntfsprogs
pam_krb5
pam_pkcs11
passwdqc
pciutils
pinfo
-plymouth
psacct
quota
-rdist
-realmd
-rng-tools
rsync
rsyslog
setuptool
smartmontools
sos
sssd
sudo
symlinks
systemd-udev
tar
tcpdump
tcp_wrappers
-telnet
time
traceroute
# tree
unzip
usbutils
# vconfig
wget
which
# wireless-tools
words
zip

# ### ### ###
# @system-tools
# ### ### ###
# ------
# default
# ------
# BackupPC
# bonnie++
chrony
# cifs-utils
# jigdo
libreswan
NetworkManager-l2tp
NetworkManager-libreswan
# NetworkManager-openconnect
NetworkManager-openvpn
NetworkManager-vpnc
nmap
-ntfs-3g
-openconnect
# openldap-clients
openvpn
# samba-client
-screen
setserial
-tigervnc
vpnc
# xdelta
# zisofs-tools
# zsh

# ### ### ###
# @headless-management
# ### ### ###
# cockpit-bridge
# cockpit-networkmanager
# cockpit-shell
# cockpit-storaged
# cockpit-ws
openssh-server
PackageKit
# rolekit
# cockpit-kubernetes
# cockpit-pcp

# ### ### ###
dnf-automatic
# dnssec-trigger
git
kernel-core
ldns-utils
tmux
vim-enhanced

# ### ### ###
crudini
xmlstarlet

akmods
dkms
# dnf-plugin-system-upgrade
redhat-lsb-core
macchanger
NetworkManager-tui
# samba
# samba-winbind
setools-console
# system-config-firewall-tui
## unburden-home-dir

-anaconda*
## korora-repos
## rpmfusion-free-release
## rpmfusion-nonfree-release
## virtualbox-release
%end

%post
tee /usr/lib/systemd/system/macspoof@.service <<-'EOF'
[Unit]
Description=macchanger on %I
Wants=network-pre.target
Before=network-pre.target
After=sys-subsystem-net-devices-%i.device

[Service]
ExecStart=/usr/bin/macchanger -r %I
Type=oneshot

[Install]
WantedBy=multi-user.target
EOF

# tee --append /etc/default/grub <<-'EOF'
# GRUB_FORCE_HIDDEN_MENU="true"
# #GRUB_GFXMODE="auto"
# GRUB_GFXPAYLOAD_LINUX="keep"
# GRUB_TERMINAL="gfxterm"
# EOF

curl -L https://gist.githubusercontent.com/anonymous/8eb2019db2e278ba99be/raw/257f15100fd46aeeb8e33a7629b209d0a14b9975/gistfile1.sh -o /etc/grub.d/31_hold_shift
crudini --set /etc/default/grub '' GRUB_FORCE_HIDDEN_MENU true
crudini --set /etc/default/grub '' GRUB_GFXPAYLOAD_LINUX keep
crudini --set /etc/default/grub '' GRUB_TERMINAL gfxterm
sed --in-place 's/ = /=/g' /etc/default/grub

[ -e /usr/share/fonts/dejavu/DejaVuSansMono.ttf ] && grub2-mkfont --output=/boot/grub2/unicode.pf2 /usr/share/fonts/dejavu/DejaVuSansMono.ttf

[ -e /boot/grub2/grub.cfg ] && grub2-mkconfig -o /boot/grub2/grub.cfg
[ -e /boot/efi/EFI/fedora/grub.cfg ] && dnf install grub2-efi-modules
[ -e /boot/efi/EFI/fedora/grub.cfg ] && grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
%end
