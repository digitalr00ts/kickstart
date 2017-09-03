# ksappend/basic.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

#%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/repos/rpmfusion.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/base/core.ks
%include https://raw.githubusercontent.com/digitalr00ts/korora-kickstart/f26/base/standard.ks

%packages

git
vim

%end

%post
#!/bin/sh

# Macchange on boot service
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

# enable discards on LVM for trim
sed -i 's/issue_discards = 0/issue_discards = 1/g' /etc/lvm/lvm.conf

%end

