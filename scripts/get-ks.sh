#!/bin/sh
[ -z $1 ] && declare x='none' || x=$1
startpath=$(pwd)
runpath='/run/install'

cd $runpath

[ $x != '--min' ] && \
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/min.cfg

if [ $x = '--all' ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/digitalr00ts-korora-common-min.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/digitalr00ts-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/fedora-live-minimization.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/fedora-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/korora-common-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/korora-xfce.ks
fi

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/digitalr00ts-repo.ks
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/korora-base.ks

mkdir --parent ${runpath}/snippets && cd $_
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/snippets/packagekit-cached-metadata.ks

mkdir --parent ${runpath}/scripts && cd $_
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/master/scripts/disk.sh
chmod +x ./disk.sh
./disk.sh

cd $startpath
