# Test kickstart files

## Requirements

* VirtualBox
* Vagrant
* Packer

## Usage

```bash
# Test in VirtualBox
packer build -only=virtualbox -name=digitalr00ts/fedora26 fedora.json

# Or with optional variable file
packer build -only=virtualbox -name=digitalr00ts/fedora26 -var-file=workstation-dvd.json fedora.json
```
