# Test kickstart files

## Requirements

* VirtualBox
* Vagrant
* Packer

## Usage

```bash
# Install Packer
./packer-install.sh

# Test in VirtualBox
./packer build -only=virtualbox-iso -debug fedora.json

# Or with optional variable file
./packer build -only=virtualbox-iso -var-file=workstation-dvd.json fedora.json
```
