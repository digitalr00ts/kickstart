
## F32

* https://pagure.io/fedora-kickstarts/tree/f32
* https://pagure.io/fedora-comps/blob/master/f/comps-f32.xml.in

## Testing

* Get Packer, https://releases.hashicorp.com/packer/
* Get Vagrant, https://releases.hashicorp.com/vagrant/

```bash
#! /usr/bin/env sh

PACKER_VER=1.5.6
VAGRANT_VER=2.2.9
SYSTEM=linux_amd64

set -e

printf -- "Downloading Packer ${PACKER_VER}\n"
curl -LSsO "https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_SHA256SUMS"
curl -LSsO "https://releases.hashicorp.com/packer/${PACKER_VER}/packer_${PACKER_VER}_${SYSTEM}.zip"
sha256sum --check --ignore-missing "packer_${PACKER_VER}_SHA256SUMS"
unar "packer_${PACKER_VER}_${SYSTEM}.zip"
rm -- "packer_${PACKER_VER}_${SYSTEM}.zip" "packer_${PACKER_VER}_SHA256SUMS"

printf -- "Downloading Vagrant ${VAGRANT_VER}\n"
curl -LSsO "https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_SHA256SUMS"
curl -LSsO "https://releases.hashicorp.com/vagrant/${VAGRANT_VER}/vagrant_${VAGRANT_VER}_${SYSTEM}.zip"
sha256sum --check --ignore-missing "vagrant_${VAGRANT_VER}_SHA256SUMS"
unar "vagrant_${VAGRANT_VER}_${SYSTEM}.zip"
rm -- "vagrant_${VAGRANT_VER}_${SYSTEM}.zip" "vagrant_${VAGRANT_VER}_SHA256SUMS"
```
