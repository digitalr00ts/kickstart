# Provisioning System

## Requirements

* Packer
* Vagrant
* Pykickstart
* Ansible
* Inspec

## Setup

```bash
ansible-galaxy role install dev-sec.os-hardening --force
ansible-galaxy install dev-sec.ssh-hardening --force
```

## Usage

### Build

```bash
cd packer
rm -rf -- output-*
./packer build template.pkr.hcl
```

### Run

```bash
cd vagrant
vagrant provision
vagrant up
ansible all -m ping
vagrant ssh
```

### Validate

```bash
packer/packer validate packer/template.pkr.hcl
ksvalidator --followincludes --version F32 kickstart/ks.cfg
```

## Notes

### To DO
* [ ] Inspec
* [ ] Push Vagrant images
* [ ] Add license

### F32

* https://pagure.io/fedora-kickstarts/tree/f32
* https://pagure.io/fedora-comps/blob/master/f/comps-f32.xml.in

