# digitalr00ts xfce kickstart file
#platform=x86, AMD64, or Intel EM64T

%include x-base.ks
services --enabled kodi
# firewall --enabled --service mdns

# user --name=kodi --iscrypted --password=$1$k4aUN3va$URZYG5mTDY2ZVnvZy.XxL/

%packages
dbus-x11
kodi
libva-utils
tlp
upower
%end

%post
useradd --system kodi

# Create Systemd Service File For X-Windows / Kodi
cat <<"EOF" >/etc/systemd/system/kodi.service
[Unit]
Description = kodi-standalone using xinit
After = remote-fs.target

[Service]
User = kodi
Group = kodi
PAMName = login
Type = simple
ExecStart = /usr/bin/xinit /usr/bin/dbus-launch /usr/bin/kodi-standalone -- :0 -nolisten tcp
Restart = on-abort

[Install]
WantedBy = multi-user.target
EOF

# Reconfigure PolicyKit To Enable Poweroff, Suspend and Similiar Functions
cat <<"EOF" >/etc/polkit-1/localauthority/50-local.d/kodi_shutdown.pkla
[Actions for kodi user]
Identity=unix-user:kodi
Action=org.freedesktop.devicekit.power.*;org.freedesktop.upower.*;org.freedesktop.consolekit.system.*;org.freedesktop.login1.*
ResultAny=yes
EOF

# Configure Xwrapper To Allow Non-Console Users, Kodi, To Start X-Server
cat <<"EOF" >/etc/X11/Xwrapper.config
allowed_users = anybody
EOF

chmod 644 /etc/X11/Xwrapper.config

# systemctl enable kodi.service
%end
