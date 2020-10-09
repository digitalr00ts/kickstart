#!/usr/bin/env sh

get_latest_release() {
    curl --silent "https://api.github.com/repos/hashicorp/${SW}/releases/latest" | grep -Po 'tag_name.*"v\K(\d\.?)+'
}

# get_latest_tag() {
#     git ls-remote --exit-code --tags --refs --sort='v:refname' "https://github.com/hashicorp/${SW}.git" 'v*' \
#         | tail --lines=1 | grep -Po 'v?\K(\d*\.?)+$'
# }

get_hashi_sw() {
    printf -- "Downloading ${SW^} ${VER}\n"
    curl -LSsO "https://releases.hashicorp.com/${SW}/${VER}/${SW}_${VER}_SHA256SUMS"
    curl -LSsO "https://releases.hashicorp.com/${SW}/${VER}/${SW}_${VER}_${SUFFIX}"
    sha256sum --check --ignore-missing "${SW}_${VER}_SHA256SUMS"
    printf ${SUFFIX} | grep -q '\.zip$' -- - && INSTALL_CMD='unzip -od bin'
    printf ${SUFFIX} | grep -q '\.rpm$' -- - && INSTALL_CMD='rpm -i'
    ${INSTALL_CMD} "${SW}_${VER}_${SUFFIX}"
    rm -- "${SW}_${VER}_${SUFFIX}" "${SW}_${VER}_SHA256SUMS"
}

bundle install --gemfile Gemfile.chef
bundle install --gemfile Gemfile.vagrant
bin/vagrant plugin install vagrant-libvirt

SW=packer
VER=$(get_latest_release)
SUFFIX=linux_amd64.zip
get_hashi_sw

for SW in pykickstart ansible; do
  pipx list | grep -qF ${SW} && pipx upgrade ${SW} || pipx install ${SW}
done

ansible-galaxy install --force --role-file requirements.yml
