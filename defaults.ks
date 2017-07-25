# defaults.ks

install
reboot
text

url --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="fedora-updates" --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

sshpw --username admin --iscrypted $6$rounds=123456$kickstart$8BDRblt8lkOOA..4iCG/xJZR6L4nl2ZJxsZ9pkoK1ECbfqkZs60Gew6j2jvVCYSi9.e.hYGK2.S1v4ZG6zpBT/

authconfig --enableshadow --passalgo=sha512
timezone America/Los_Angeles --isUtc --ntpservers=0.pool.ntp.org,1.pool.ntp.org,2.pool.ntp.org,3.pool.ntp.org

keyboard 'us'
lang en_US.UTF-8

selinux --permissive

firewall --enabled --service=sshd
services --enabled=sshd --disabled=libvrtd,docker,docker-engine
