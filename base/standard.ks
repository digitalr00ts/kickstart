# base/standard.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Standard
# Description: Common set of utilities that extend the minimal installation.

%packages
-abrt-cli
#acl
#at
attr
bash-completion
-bc
bind-utils
bridge-utils
-btrfs-progs
bzip2
cifs-utils
#coolkey
#cpio
crontabs
cryptsetup
-cyrus-sasl-plain
dbus
deltarpm
#dos2unix
dosfstools
-ed
#ethtool
-fedora-release-notes
file
-fpaste
-fprintd-pam
#gnupg2
#hunspell
#iptstate
irqbalance
-jwhois
logrotate
lsof
#mailcap
man-pages
mcelog
#mdadm
microcode_ctl
#mlocate
mtr
-nano
net-tools
nfs-utils
#nmap-ncat
-ntfs-3g
-ntfsprogs
#pam_krb5
#pam_pkcs11
#passwdqc
pciutils
#pinfo
-plymouth
#psacct
#quota
-realmd
-rng-tools
rsync
#rsyslog
#setuptool
smartmontools
-sos
#sssd
sudo
symlinks
systemd-udev
tar
tcpdump
#tcp_wrappers
-telnet
time
traceroute
#tree
unzip
usbutils
util-linux-user
vconfig
#wget
which
-wireless-tools
#words
zip

# type="conditional" requires="control-center"
# chrony

%end

