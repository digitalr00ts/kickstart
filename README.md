
## F32

* https://pagure.io/fedora-kickstarts/tree/f32
* https://pagure.io/fedora-comps/blob/master/f/comps-f32.xml.in

## Testing

Get Packer, https://releases.hashicorp.com/packer/

```bash
#! /usr/bin/env sh

VERSION=1.5.6
SYSTEM=linux_amd64

set -e

curl -LSsO "https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_SHA256SUMS"
curl -LSsO "https://releases.hashicorp.com/packer/${VERSION}/packer_${VERSION}_${SYSTEM}.zip"
sed -e "/${SYSTEM}/!d" -i'' "packer_${VERSION}_SHA256SUMS"
sha256sum --check "packer_${VERSION}_SHA256SUMS"
unar "packer_${VERSION}_${SYSTEM}.zip"
rm -- "packer_${VERSION}_${SYSTEM}.zip" "packer_${VERSION}_SHA256SUMS"
```
