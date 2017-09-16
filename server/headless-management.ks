# server/core.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

# Group Name: Headless Management
# Description: Tools for managing the system without an attached graphical console.

%packages

# Mandatory
cockpit-bridge
cockpit-networkmanager
cockpit-shell
cockpit-storaged
cockpit-ws
openssh-server
PackageKit
rolekit

# Optional
#cockpit-kubernetes
# Fatal error on installation, disabling for now
# cockpit-pcp

# Not Included
# Anaconda throws error that is missing even though it is in comps-f26.xml
#docker-cockpit
#pcp-pmda-kvm
#tuned
#tuned-utils-systemtap

# Kimchi in repo is very old. v1.5.1
#kimchi

# Kimchi Runtime Dependencies - https://github.com/kimchi-project/kimchi/blob/master/docs/fedora-deps.md
libvirt-python
libvirt
libvirt-daemon-config-network
qemu-kvm
python-ethtool
sos
python-ipaddr
nfs-utils
iscsi-initiator-utils
pyparted
python-libguestfs
libguestfs-tools
novnc
spice-html5
python-configobj
python-magic
python-paramiko
python-pillow

#WARNING: no 'numpy' module, HyBi protocol will be slower

# For SELinux - https://www.timothygruber.com/linux/fedora-26-kvm-html5-remote-access-with-web-console-via-kimchi-part-1/
policycoreutils-python-utils

%end

%post
#!/bin/sh

# Install Kimchi http://kimchi-project.github.io/kimchi/downloads/
for package in wok kimchi; do
  curl -SsLO http://kimchi-project.github.io/wok/downloads/latest/${package}.fedora.noarch.rpm
  dnf install ./${package}.fedora.noarch.rpm
done

tee /usr/lib/firewalld/services/kimchid.xml <<-'EOF'
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>kimchid</short>
  <description>Kimchid is a daemon service for kimchi which is a HTML5 based management tool for KVM. It is designed to make it as easy as possible to get started with KVM and create your first guest.</description>
  <port protocol="tcp" port="8000"/>
  <port protocol="tcp" port="8001"/>
  <port protocol="tcp" port="64667"/>
</service>
EOF

tee /usr/lib/systemd/system/kimchid.service <<-'EOF'
[Unit]
Description=Kimchi server
Documentation=https://github.com/kimchi-project/kimchi/
Requires=libvirtd.service
After=libvirtd.service
Wants=nginx.service
After=nginx.service
Wants=apache2.service
After=apache2.service

[Service]
Type=simple
ExecStart=/usr/bin/wokd
ExecStop=/bin/kill -TERM $MAINPID
EnvironmentFile=/etc/wok/wok.conf
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

%end
