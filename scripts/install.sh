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

for SW in vagrant chef; do
  echo ${SW}
  BUNDLE_GEMFILE=Gemfile.${SW} bundle update || bundle install --gemfile Gemfile.${SW}
done
bin/vagrant plugin install vagrant-libvirt

SW=packer
VER=$(get_latest_release)
SUFFIX=linux_amd64.zip
if [ ! -x "bin/${SW}" ] || [ "$(${SW} --version | grep -Po '(\d*\.){2}\d*$')" == "${VER}" ]; then
  get_hashi_sw
else
  printf "${SW^} ${VER} already installed.\n"
fi

if which pipx &> /dev/null; then
  while IFS="" read -r SW || [ -n "${SW}" ]; do
    pipx list | grep -qF ${SW} && pipx upgrade ${SW} || pipx install ${SW} --include-deps
  done < requirements.txt
  ansible-galaxy install --force --role-file requirements.yml
else
  python3 -m venv .venv
  .venv/bin/python3 -m pip install -r requirements.txt
  .venv/bin/ansible-galaxy install --force --role-file requirements.yml
  printf 'Enable Python virtual environment: `. .venv/bin/activate`'
fi
