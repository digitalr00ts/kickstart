# Provisioning System

## Summary

### Features
* OS Hardening
* CIS Linux Baseline Benchmark
* Vagrant Base Image
* Ansible Playbooks/Roles/Tasks

### Requirements

* [QEMU](https://www.qemu.org/)
* [Packer]()
* [Ansible]()
* [Vagrant]
* [libvirt]

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
./scripts/install.sh
```

## Usage

### Build

```bash
bin/packer build -timestamp-ui -force -var-file='packer/f36.pkrvars.hcl' -only='*.virtualbox-iso.*' packer
bin/packer build -timestamp-ui -force -only='*.qemu.*' packer
```

## Other Usage

### Run

```bash
bin/vagrant provision
bin/vagrant up
ansible all -m ping
bin/vagrant ssh
```

### Validate

```bash
bin/packer validate packer/template.pkr.hcl
ksvalidator --followincludes --version F32 kickstart/ks.cfg
```

## Usage via Docker

NOTE: Working in progress

FIXME: Networking between containers and KVM.

```sh
docker-compose build --compress --pull --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg GID_LIBVIRT=$(getent group libvirt | cut -d':' -f3)
docker-compose run --rm -e PACKER_LOG=1 provisioner packer build -force packer/template.pkr.hcl

remote-viewer spice+unix://output/qemu/fedora32.spice
minicom -D unix\#output/qemu/fedora32.console
```

## Setup on Mac

NOTE: WIP, might need to create a spice-server formula

The prebuilt QEMU binaies do not have support for the [SPICE](https://spice-space.org/) protocol.

1. ```sh
   brew install openssl@3
   # brew link openssl, maybe
   ```
1. ```
   git clone --depth 1 --tag v0.15.0 https://gitlab.freedesktop.org/spice/spice.git
   PKG_CONFIG_PATH="/usr/local/opt/openssl@3/lib/pkgconfig" LDFLAGS="-L/usr/local/opt/openssl@3/lib" CPPFLAGS="-I/usr/local/opt/openssl@3/include" ./configure --disable-sasl --disable-tests --prefix=/usr/local/opt/spice-server --libdir=/usr/local/opt/spice-server/lib --includedir=/usr/local/opt/spice-server/include
   ln -sv /usr/local/opt/spice-server/lib/pkgconfig/spice-server.pc /usr/local/share/pkgconfig/spice-server.pc
   ln -sv /usr/local/opt/spice-server/lib/pkgconfig/spice-server.pc /usr/local/opt/spice-protocol/share/pkgconfig  # Hack for brew, until i make a formula
   ```
1. Edit the brew formula for QEMU
    ```sh
    brew edit qemu
    ```
    In `Class Qemu < Formula`:
    1. Add `depends_on spice-protocol`
    2. Under `def install` add `--enable-spice` to list for `args`
1. Build QEMU
    ```
    PKG_CONFIG_PATH="/usr/local/opt/spice-server/lib/pkgconfig" \
    LDFLAGS="-L/usr/local/opt/spice-server/lib" \
    CFLAGS="-I/usr/local/opt/spice-server/include/" \
    brew install --build-from-source --verbose qemu
    ```
1.  ```sh
    brew install libvirt
    ```
    ```
    PKG_CONFIG_PATH="/usr/local/opt/spice-protocol/share/pkgconfig/:/usr/local/opt/pixman/lib/pkgconfig/:/usr/local/opt/glib/lib/pkgconfig/:/usr/local/opt/spice-server/lib/pkgconfig:$PKG_CONFIG_PATH" LDFLAGS="-L/usr/local/opt/spice-server/lib" CPPFLAGS="-I/usr/local/opt/spice-server/include/" LIBTOOL=glibtool ./configure --prefix="${HOMEBREW_FORMULA_PREFIX}" --disable-bsd-user --disable-guest-agent --enable-curses --enable-libssh --enable-slirp=system --enable-vde --enable-virtfs --enable-zstd --extra-cflags=-DNCURSES_WIDECHAR=1 --disable-sdl --enable-spice --smbd="${HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd" --disable-gtk --enable-cocoa
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
