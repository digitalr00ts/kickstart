# repos/rpmfussion.ks
# platform=x86, AMD64, or Intel EM64T
# digitalr00ts kickstart file

repo --name rpmfusion-free --mirrorlist http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch --cost 1000
repo --name rpmfusion-nonfree --mirrorlist http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch --cost 1001

%packages

rpmfusion-free-release
rpmfusion-nonfree-release

%end

