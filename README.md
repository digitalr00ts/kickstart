# Provisioning System

## Summary

## Features
* OS Hardening
* CIS Linux Baseline Benchmark
* Vagrant Base Image
* Ansible Playbooks/Roles/Tasks

### F32 References

* https://pagure.io/fedora-kickstarts/tree/f32
* https://pagure.io/fedora-comps/blob/master/f/comps-f32.xml.in

## Requirements

* Packer
* Vagrant
* Pykickstart
* Ansible
* [Inspec](https://community.chef.io/products/chef-inspec/)
* [DevSec Hardening Framework](https://dev-sec.io/)
  * [os-hardening](https://github.com/dev-sec/ansible-os-hardening)
  * [ssh-hardening](https://github.com/dev-sec/ansible-ssh-hardening)
  * [CIS Distribution Independent Linux Benchmark](https://github.com/dev-sec/cis-dil-benchmark/blob/master/inspec.yml)
## Setup

```bash
ansible-galaxy role install dev-sec.os-hardening --force
ansible-galaxy install dev-sec.ssh-hardening --force
```

## Usage

### Build

```bash
# cd packer
# rm -rf -- output-*
# ./packer build template.pkr.hcl
packer build -force packer/template.pkr.hcl
```

## Other Usage

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

## To DO
* [ ] Inspec
* [ ] Push Vagrant images to Atlas
* [ ] Ansible lint
* [ ] Test Kitchen
* [ ] OSCAP/NIST
* [ ] Docker base image
* [ ] Ansible playbooks
  * [ ] Gnome Desktop

## License

<pre>
Copyright 2020 digitalr00ts

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
</pre>
