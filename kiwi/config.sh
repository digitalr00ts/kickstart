#!/bin/bash
set -euxo pipefail

passwd -l root || true

cat >> /etc/dnf/dnf.conf <<'EOF'
install_weak_deps=False
fastestmirror=True
repo_gpgcheck=True
timeout=10
max_parallel_downloads=8
EOF

rm -f /var/lib/systemd/random-seed /etc/machine-id && touch /etc/machine-id

systemctl enable sshd NetworkManager firewalld

[[ -f /etc/selinux/config ]] && sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

dnf clean all
truncate -c -s 0 /var/log/dnf*.log 2>/dev/null || true

rpm -qa | sort

rm -f /var/lib/rpm/__db* /root/build-post.log
journalctl --vacuum-time=1s || true
rm -rf /tmp/* /var/tmp/* || true
