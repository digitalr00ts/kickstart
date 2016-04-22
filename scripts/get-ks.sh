#!/bin/sh
startpath=$(pwd)
runpath='/run/install'
branch=master
skip_min=0
desktop=0

opts=$(getopt --options b:dm --long branch:,desktop,min --name 'get-ks.sh' -- "$@")
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
    --) shift; break ;;
    *) echo "Invaild option: $1"; exit 1;
  esac
done

cd $runpath

[ $skip_min -eq 0 ] && \
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/min.cfg

if [ $desktop  -eq 1 ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/digitalr00ts-korora-common-min.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/digitalr00ts-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/fedora-live-minimization.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/fedora-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/korora-common-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/korora-xfce.ks
fi

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/digitalr00ts-repo.ks
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/korora-base.ks

mkdir --parent ${runpath}/snippets && cd $_
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/snippets/packagekit-cached-metadata.ks

mkdir --parent ${runpath}/scripts && cd $_
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/scripts/scripts/disk.sh
chmod +x ./disk.sh
./disk.sh

cd $startpath
