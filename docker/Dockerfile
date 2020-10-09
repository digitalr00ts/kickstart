FROM registry.fedoraproject.org/fedora:rawhide

ARG UID=5150
ARG GID=5150
ARG GID_LIBVIRT=972
WORKDIR /dev/shm
# vagrant plugin install vagrant-libvirt vagrant-sshfs
# cp -R ~/.vagrant.d/gems/*/* /opt/vagrant/embedded/gems/2.2.7/
# cp ~/.vagrant.d/plugins.json /opt/vagrant/embedded/plugins.json
# rm -rf ~/.vagrant.d/

    # bundle config set --global system true &&\
    # Add libvirt groups w/ gid of host and add to builder
RUN set -ex ;\
    sed -i'' -e 's/^enabled=1$/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo /etc/yum.repos.d/fedora-rawhide-modular.repo &&\
    printf -- \
        'install_weak_deps=False\nfastestmirror=True\nrepo_gpgcheck=True\ntimeout=10\nassumeyes=True\nautocheck_running_kernel=False\nbest=False\ndiskspacecheck=False\ngroup_package_types=mandatory\nlogfilelevel=0' \
        >> /etc/dnf/dnf.conf &&\
    dnf install \
        ruby rubygems qemu-system-x86-core qemu-img libvirt-libs bsdtar &&\
    printf -- "gem: --no-document" >> /etc/gemrc &&\
    gem install bundler &&\
    curl -Ss https://bootstrap.pypa.io/get-pip.py | python3 &&\
    printf -- \
        "[global]\ndisable-pip-version-check = true\nno-cache-dir = false\ncompile = true\nprogress-bar = off\nuse-feature = 2020-resolver" \
        >> /etc/pip.conf &&\
    groupadd --system -g ${GID_LIBVIRT} -o libvirt &&\
    groupadd -g ${GID} -o builder &&\
    useradd -mg ${GID} -G users,libvirt -c 'Image Builder' -u ${UID} builder &&\
    echo
    # dnf autoremove &&\
    # dnf clean all &&\
    # rm -rf -- /var/lib/dnf &&\
    # :>/var/log/lastlog

    # CONFIGURE_ARGS='with-ldflags=-L/opt/vagrant/embedded/lib64 with-libvirt-include=/usr/include/libvirt with-libvirt-lib=/usr/lib64' \
    #     vagrant plugin install vagrant-libvirt &&\
    # cp -R "~/.vagrant.d/gems/*/*" /opt/vagrant/embedded/gems/*.*.*/ &&\
    # cp -f "~/.vagrant.d/plugins.json" /opt/vagrant/embedded/plugins.json &&\
    # rm -rf -- "~/.vagrant.d/" &&\
    # sudo --user builder bundle config set --global disable_version_check true &&\
    # sudo --user builder bundle config set --global no-cache true &&\
    # sudo --user builder bundle config set --global bin ${DEP_PATH}/.local/bin &&\
    # sudo --user builder bundle config set --global path ${DEP_PATH}/.bundle/vendor &&\
    # sudo --set-home --login --user builder bundle install --gemfile=${DEP_PATH}/Gemfile.chef &&\
    # sudo --set-home --login --user builder bundle install --gemfile=${DEP_PATH}/Gemfile.vagrant &&\
RUN set -ex ;\
    dnf install \
        git-core redhat-rpm-config ruby-devel libvirt-devel libxml2-devel gcc g++ make \
        dnf-plugins-core cpio xz cmake zlib-devel &&\
    echo
COPY Gemfile.chef Gemfile.vagrant requirements.txt requirements.yml install_hashi.sh /opt/deps/
COPY .bundle /root/.bundle
COPY .bundle /home/builder/.bundle
RUN set -ex ;\
    export DEP_PATH='/opt/deps' &&\
    bundle install --gemfile=${DEP_PATH}/Gemfile.chef &&\
    bundle install --gemfile=${DEP_PATH}/Gemfile.vagrant &&\
    sudo --non-interactive --set-home --login --user builder vagrant plugin install vagrant-libvirt
    # ${DEP_PATH}/install_hashi.sh &&\
    # dnf install vagrant-libvirt &&\
    # bundle install --gemfile ${DEP_PATH}/Gemfile &&\
    # pip3 install -r ${DEP_PATH}/requirements.txt &&\
    # pip3 freeze > ${DEP_PATH}/requirements.in &&\
    # ansible-galaxy install --roles-path /usr/share/ansible/roles --role-file ${DEP_PATH}/requirements.yml &&\
    # dnf remove \
    #     git-core redhat-rpm-config ruby-devel libvirt-devel libxml2-devel gcc g++ make &&\
    # dnf autoremove &&\
    # dnf clean all &&\
    # rm -rf -- ~/.cache ~/.bundle/cache ~/.gem /var/lib/dnf &&\
    # :>/var/log/lastlog
    #rubygem-erubis

USER builder
WORKDIR /home/builder
# RUN cd; set -ex ;\
    # bundle config set --global bin "${HOME}/.local/bin" &&\
    # bundle install --gemfile Gemfile.chef --path .bundle/chef


# ENV EXECUTABLE DIRECTOR="/home/builder/.local/bin"
#ENTRYPOINT [ "bash" ]cd
