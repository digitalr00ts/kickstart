# repos/docker-ce.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

%pre-install
#!/bin/sh
dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
%end

