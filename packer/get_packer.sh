#! /usr/bin/env bash

set -e
SYSTEM=linux_amd64

get_latest_release() {
    curl --silent "https://api.github.com/repos/hashicorp/$1/releases/latest" | grep -Po 'tag_name.*"v?\K(\d\.?)+'
}

for sw in packer ; do
    ver="$(get_latest_release ${sw^})"
    printf -- "Downloading ${sw^} ${ver}\n"
    curl -LSsO "https://releases.hashicorp.com/${sw}/${ver}/${sw}_${ver}_SHA256SUMS"
    curl -LSsO "https://releases.hashicorp.com/${sw}/${ver}/${sw}_${ver}_${SYSTEM}.zip"
    printf -- "Extracting\n"
    sha256sum --check --ignore-missing "${sw}_${ver}_SHA256SUMS"
    unar -f "${sw}_${ver}_${SYSTEM}.zip"
    rm -- "${sw}_${ver}_${SYSTEM}.zip" "${sw}_${ver}_SHA256SUMS"
done

# CONFIGURE_ARGS='with-ldflags=-L/opt/vagrant/embedded/lib with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib' \
# CONFIGURE_ARGS="with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib64" \
#   GEM_HOME=~/.vagrant.d/gems \
#   GEM_PATH=$GEM_HOME:/opt/vagrant/embedded/gems \
#   PATH=/opt/vagrant/embedded/bin:$PATH \
#   ./vagrant plugin install vagrant-libvirt
