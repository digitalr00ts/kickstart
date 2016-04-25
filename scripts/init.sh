#!/bin/bash
set -o nounset
set -o errexit

# Check for block device
function block_check () {
  [ -d /sys/block/vda ] && echo vda && return 0
  [ -d /sys/block/sda ] && echo sda && return 0
  [ -d /sys/block/hda ] && echo hda && return 0
  echo "No block device that I recognize" >&2 ; return 1
}

# ### ### ###
# Initialize variables
# ### ### ###
[ -z ${startpath+x} ] && declare -x startpath="$(pwd)"
[ -z ${runpath+x} ] && declare -x runpath='/run/install'
[ -z ${branch+x} ] && declare -x branch='master'
[ -z ${desktop+x} ] && declare -x desktop=0
declare -x blockdevice=$(block_check) ; [ ! $blockdevice ] && exit 1
declare -x skip_min=0
declare -x micro=0

curl_options='--progress-bar --location --remote-name'

# ### ### ###
# Parse arguments
# ### ### ###
opts=$(getopt --options b:dm --long branch:,desktop,min,micro --name 'get-ks.sh' -- "$@")
eval set -- "$opts"

while true; do
  case "$1" in
    -b|--branch)
      if [ -n $2 ] ; then
        branch=$2 ; shift 2 ;
      else
        echo "Option requires argument" ; exit 1 ;
      fi ;;
    -d|--desktop) desktop=1 ; shift ;;
    -m|--min) skip_min=1 ; shift ;;
    --micro) micro=1 ; shift ;;
    --) shift; break ;;
    *) echo "Invaild option: $1"; exit 1;
  esac
done

# ### ### ###
# Get nessacary files
# ### ### ###
cd $runpath

if [ $desktop  -eq 1 ] ; then
  echo -n 'digitalr00ts-korora-common-min.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/digitalr00ts-korora-common-min.ks
  echo -n 'digitalr00ts-xfce-packages.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/digitalr00ts-xfce-packages.ks
  echo -n 'fedora-live-minimization.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/fedora-live-minimization.ks
  echo -n 'fedora-xfce-packages.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/fedora-xfce-packages.ks
  echo -n 'korora-common-packages.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/korora-common-packages.ks
  echo -n 'korora-xfce.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/korora-xfce.ks
fi

if [ ! $micro -eq 1 ] ; then
  echo -n 'digitalr00ts-repo.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/digitalr00ts-repo.ks
  [ $skip_min -eq 0 ] && \
    echo -n 'min.cfg: '
    curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/min.cfg
fi

echo -n 'korora-base.ks: '
curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/korora-base.ks

mkdir --parent ${runpath}/snippets && cd $_
echo -n 'packagekit-cached-metadata.ks: '
curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/snippets/packagekit-cached-metadata.ks

mkdir --parent ${runpath}/scripts && cd $_
echo -n 'partitions.sh: '
curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/scripts/partitions.sh
chmod +x ./partitions.sh
echo -n 'vm-guests.sh: '
curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/scripts/vm-guests.sh
chmod +x ./vm-guests.sh

# ### ### ###
#   Runing scripts
# ### ### ###
${runpath}/scripts/partitions.sh || exit 1
${runpath}/scripts/vm-guests.sh $([ $desktop -eq 1 ] && echo '--desktop') $([ $blockdevice == 'vda' ] && echo '--qemu')

# ### ### ###
# End by returning to starting directory
# ### ### ###
cd $startpath
