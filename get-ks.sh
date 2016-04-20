#!/bin/sh
[ -z $1 ] && declare x=' ' || x=$1
runpath='/run/install'

cd $runpath

if [ $x != '--min' ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/min.cfg
elif [ $x = '--all' ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-korora-common-min.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/fedora-live-minimization.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/fedora-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-common-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-xfce.ks
fi

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/disk.sh
chmod +x ./disk.sh
./part.sh

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-repo.ks
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-base.ks

mkdir --parent $runpath/snippets && cd - && cd $runpath/snippets
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/snippets/packagekit-cached-metadata.ks
cd -
