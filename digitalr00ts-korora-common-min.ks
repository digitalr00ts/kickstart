# digitalr00ts-korora-common-min.ks
# Slimming korora-common-packages.ks

%packages
# firstboot
uget
smplayer
qpdfview
gpicview
shutter
AcetoneISO
pcmanfm
dnf-automatic
ldns
dnssec-trigger
dnssec-trigger-panel

#
# THIRD PARTY
# adobe-release
# google-chrome-release
# google-earth-release
# google-talkplugin-release
# virtualbox-release

#
# ACCESSIBILITY
-eekboard

#
# ARCHIVING
-arj
-lha
-p7zip
-p7zip-plugins
# rar
-unace
# -unrar
-unar
# xz-lzma-compat

#
# BRANDING
# korora-extras
# korora-release
# korora-logos
# -fedora-release-notes
-korora-welcome
-plymouth-theme-korora
-grub2-efi
-efibootmgr
# korora-icon-theme-base
# korora-icon-theme
-korora-productimg-workstation
# -korora-release-workstation
# -fedora-release-workstation
# -f22-backgrounds*
# freetype-freeworld

#
# CLOUD
-owncloud-client

#
# DEVELOPMENT / DEBUGGING
-android-tools
#createrepo
-fpaste # fpaste is very useful for debugging and very small
-gcc
# git
# ltrace
# ntfsprogs
# openssh-askpass
# strace
# vim

#
# DEVICE DRIVER / FIRMWARE MANAGEMENT
-*firmware*
-b43-firmware-helper
-b43-firmware
-akmods
# dkms
-kernel-devel
# pharlap

#
# FILESYSTEMS
-btrfs-progs
# exfat-utils
# fuse
# fuse-exfat
# gparted
# hdparm
# samba
# samba-winbind

#
# FONTS
# aajohan-comfortaa-fonts  # need aajohan-comfortaa-fonts for the SVG rnotes images
# open-sans-fonts

#
# GAMING PLATFORM
#removed due to bad selinux requirements. only people who want steam will get that
-steam

#
# NETWORKING
-pptp-setup

#
# HARDWARE
-epson-inkjet-printer-escpr # support for recent Epson inkjet printers
-hplip # support for extra HP printers
-hpijs
-libsane-hpaio # support for extra HP scanners
# libva-intel-driver
# mesa-libEGL # fix 32bit breaking X when pulling in nvidia packages
-sane-backends
-sane-backends-drivers-scanners
-sane-backends-drivers-cameras
-spice-server
-spice-vdagent
# splix

#
# HARDWARE MONITORING/CONTROLLING
# htop
# ksm
# powertop

#
# MULTIMEDIA
-HandBrake-gui
# alsa-plugins-pulseaudio
# alsa-utils
-audacity-freeworld
-dvb-apps
#faac
#ffmpeg
#ffmpegthumbnailer
#flac
#flash-plugin.%%KP_BASEARCH%%
#flash-plugin.i386  # remove 32bit, now that we don't ship steam
# gstreamer-ffmpeg
-gstreamer-plugins-bad
-gstreamer-plugins-bad-free
-gstreamer-plugins-bad-free-extras
-gstreamer-plugins-bad-nonfree
# gstreamer-plugins-good
# gstreamer-plugins-good-extras
-gstreamer-plugins-ugly
# gstreamer1-libav
-gstreamer1-plugins-bad-free
-gstreamer1-plugins-bad-free-extras
-gstreamer1-plugins-bad-freeworld
# gstreamer1-plugins-good
# gstreamer1-plugins-good-extras
-gstreamer1-plugins-ugly
# jack-audio-connection-kit
# lame
# libaacs
# libbluray
# libdvdcss
# libdvdnav
# libdvdread
-vlc
-vlc-extras
# vorbis-tools

#
# OFFICE / PRODUCTIVITY SUITE
# @libreoffice
# libreoffice-langpack-en
# libreoffice-ogltrans
# libreoffice-opensymbol-fonts
# libreoffice-pdfimport
# libreoffice-ure
# libreoffice-xsltfilter

#
# PACKAGE MANAGEMENT

# manage copr repos
#dnf-plugins-core
#dnf-plugin-system-upgrade
#dnf-command(repomanage)
#dnf-command(versionlock)

#yum-plugin-copr

yumex-dnf
#yum-plugin-priorities
#yum-plugin-refresh-updatesd
#yum-plugin-versionlock
#yum-updatesd


#
# SYSTEM ADMINISTRATION / CONFIGURATION
-canvas
-ntp
-system-config-date
-system-config-firewall*
-system-config-keyboard
-system-config-language
-system-config-users
# fonts-tweak-tool
-liveusb-creator
# policycoreutils-gui
# polkit-desktop-policy
#prelink
-screen
-screenfetch
#setools-console
#system-config-samba
#system-config-services
#systemd-ui - N/A - f22
#tmux

#
# TERMINAL ENHANCEMENTS

# bash-completion
# moe
# unburden-home-dir

#
# WEB
# firefox
-mozilla-adblock-plus
#mozilla-ublock-origin
#mozilla-xclear

# TO SORT
#aspell-en
#chrony
-execstack
-expect
# fprintd-pam
-frei0r-plugins
-java-1.8.0-openjdk
-icedtea-web
-libimobiledevice
# mlocate
# PackageKit-browser-plugin
# PackageKit-command-not-found
# PackageKit-gstreamer-plugin
# pavucontrol
-planner
# pybluez
# redhat-lsb-core
# time
# xorg-x11-apps
# xorg-x11-resutils

%end

%post

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/fedora/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

%end
