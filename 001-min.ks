#version=F25
#platform=x86, AMD64, or Intel EM64T
# digitalr00ts minimal kickstart file

install
repo --name="Fedora-Everything" --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-$releasever&arch=$basearch
repo --name="Fedora-Update" --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f$releasever&arch=$basearch

keyboard 'us'
lang en_US.UTF-8

eula --agreed
reboot

auth --useshadow --passalgo=sha512 --enablefingerprint
selinux --enforcing

sshpw --username=root '' --lock
sshpw --username=commander $1$k4aUN3va$URZYG5mTDY2ZVnvZy.XxL/ --iscrypted

user --name=superuser --groups=wheel --iscrypted --password=$1$k4aUN3va$URZYG5mTDY2ZVnvZy.XxL/

%packages --excludedocs
@core --nodefaults
%end

%pre --log=/tmp/min.cfg-pre.log
#!/bin/bash
function block_check () {
 [ -d /sys/block/vda ] && echo vda && return 0
 [ -d /sys/block/sda ] && echo sda && return 0
 [ -d /sys/block/hda ] && echo hda && return 0
 echo "No block device that I recognize" >&2 ; return 1
}

# Initialize global variables if necessary
# Constants
[ -z ${startpath+x} ] && declare -x startpath="$(pwd)"
[ -z ${runpath+x} ] && declare -x runpath='/run/install'
[ -z ${curl_options+x} ] && curl_options='--progress-bar --location --remote-name'
[ -z ${blockdevice+x} ] && declare -x blockdevice=$(block_check) ; [ ! $blockdevice ] && exit 1
# Variables
[ -z ${branch+x} ] && declare -x branch='f25'
[ -z ${desktop+x} ] && declare -x desktop=0
# [ -z ${cfg+x} ] && declare -x cfg='base'

# Checks for kickstart files and scripts
# If not found will pull from Github
# if [ ! -f ${startpath}/scripts/curl.sh ] ; then
#   echo "Pulling Kicstart files and scripts from Github" >&2
#   echo "Using branch: ${branch}" >&2
#   mkdir --parent $runpath/scripts && cd $_
#   echo -n 'curl.sh: '
#   curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/scripts/curl.sh
#   chmod +x curl.sh
#   ${runpath}/scripts/curl.sh
#   cd ${startpath}
# fi

#   Run scripts
# if [ ! -f ${startpath}/partitions.ks ] ; then
#   ${runpath}/scripts/partitions.sh || exit 1
#   ${runpath}/scripts/vm-guests.sh $([ $desktop -eq 1 ] && echo '--desktop') $([ $blockdevice == 'vda' ] && echo '--qemu')
# fi

# Obtain scripts
mkdir --parent ${runpath}/scripts && cd $_
echo -n 'partitions.sh: '
curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/scripts/partitions.sh
chmod +x ./partitions.sh
cd $startpath

#   Run scripts
[ ! -f ${startpath}/partitions.ks ] && ${runpath}/scripts/partitions.sh || exit 1
#   ${runpath}/scripts/vm-guests.sh $([ $desktop -eq 1 ] && echo '--desktop') $([ $blockdevice == 'vda' ] && echo '--qemu')

%end

%post
sed -i 's/rhgb\|quiet//g' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

# From korora-base.ks

# group for any vbox users
/usr/sbin/groupadd -r vboxusers

# disable all abrt services, we can't upload to bugzilla
for x in abrtd abrt-ccpp abrt-oops abrt-vmcore abrt-xorg ; do
  systemctl disable $x
done

# import keys
echo -e "\n***\nIMPORTING KEYS\n***"
for x in 20 21 22 23 24
do
  for y in adobe fedora-$x-primary fedora-$x-secondary google-chrome google-earth google-talkplugin korora-$x-primary korora-$x-secondary rpmfusion-free-fedora-$x-primary rpmfusion-nonfree-fedora-$x-primary virtualbox
  do
    KEY="/etc/pki/rpm-gpg/RPM-GPG-KEY-${y}"
    if [ -r "${KEY}" ];
    then
      rpm --import "${KEY}" && echo "IMPORTED: $KEY (${y})"
    else
      echo "IMPORT KEY NOT FOUND: $KEY (${y})"
    fi
  done
done

# enable magic keys
# echo "kernel.sysrq = 1" >> /etc/sysctl.conf

# enable discards on LVM for trim
sed -i 's/issue_discards = 0/issue_discards = 1/g' /etc/lvm/lvm.conf
%end
