#!/bin/sh
cd /run/install

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/part.sh
chmod +x ./part.sh
./part.sh

curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-repo.ks
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-base.ks

mkdir /run/install/snippets && cd - && cd /run/install/snippets
curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/snippets/packagekit-cached-metadata.ks

if [ $1 != '--mini' ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/min.cfg
elif [ $1 = '--all' ] ; then
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-korora-common-min.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/digitalr00ts-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/fedora-live-minimization.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/fedora-xfce-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-common-packages.ks
  curl --location --remote-name https://github.com/digitalr00ts/korora-kickstart/raw/mini/korora-xfce.ks
fi

cd -
