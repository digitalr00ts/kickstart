#!/bin/bash
set -o nounset
set -o errexit

# ### ### ###
# Initialize variables
# ### ### ###
[ -z ${startpath+x} ] && declare -x startpath="$(pwd)"
[ -z ${runpath+x} ] && declare -x runpath='/run/install'
[ -z ${branch+x} ] && declare -x branch='master'
[ -z ${desktop+x} ] && declare -x desktop=0
[ -z ${cfg+x} ] && declare cfg=''
[ -z ${curl_options+x} ] && curl_options='--progress-bar --location --remote-name'

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
    -c|--cfg)
      if [ -n $2 ] ; then
        cfg=$2 ; shift 2 ;
      else
        echo "Option requires argument" ; exit 1 ;
      fi ;;
    -d|--desktop) desktop=1 ; shift ;;
    --micro) micro=1 ; shift ;;
    --) shift; break ;;
    *) echo "Invaild option: $1"; exit 1;
  esac
done

# ### ### ###
# Get nessacary files
# ### ### ###
cd $runpath

# if [ $desktop  -eq 1 ] ; then
#   echo -n 'digitalr00ts-korora-common-min.ks: '
#   curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/digitalr00ts-korora-common-min.ks
#  echo -n 'digitalr00ts-xfce-packages.ks: '
#  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/digitalr00ts-xfce-packages.ks
#  echo -n 'fedora-live-minimization.ks: '
#  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/fedora-live-minimization.ks
#  echo -n 'fedora-xfce-packages.ks: '
#  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/fedora-xfce-packages.ks
#  echo -n 'korora-common-packages.ks: '
#  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/korora-common-packages.ks
#  echo -n 'korora-xfce.ks: '
#  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/korora-xfce.ks
# fi

if [ ! $cfg = 'min' ] ; then
  echo -n 'repos.ks: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/repos.ks
  echo -n 'min.cfg: '
  curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/min.cfg
  if [ ! $cfg = 'base' ] ; then
    echo -n 'base.cfg: '
    curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/base.cfg
  fi
fi

if [ $desktop eq 1 ] ; then
  if [ ! $cfg = 'base-x' ] ; then
    echo -n 'base-x.cfg: '
    curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/base-x.cfg
    if [ ! $cfg = 'xfce-min' ] ; then
      echo -n 'xfce-min.cfg: '
      curl ${curl_options} https://github.com/digitalr00ts/korora-kickstart/raw/$branch/xfce-min.cfg
    fi
  fi
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
# End by returning to starting directory
# ### ### ###
cd $startpath
