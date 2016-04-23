# REPOS

# Fedora
# repo --name=fedora-mirrors --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
# repo --name="fedora-updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name="Fedora-Everything" --baseurl=http://dl.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/ --cost=1000
repo --name="Fedora-Update" --baseurl=http://dl.fedoraproject.org/pub/fedora/linux/updates/$releasever/$basearch/ --cost=1000

# Korora
repo --name="Korora" --mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror.lst --cost=10
# repo --name="Korora" --baseurl=http://dl.kororaproject.org/pub/korora/releases/$releasever/$basearch/ --cost=10

# RPM Fusion
repo --name="RPMFusion-Free" --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch --cost=1000
repo --name="RPMFusion-Free-Updates" --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch --cost=1000
repo --name="RPMFusion-Non-Free" --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch --cost=1000
repo --name="RPMFusion-Non-Free-Updates" --mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch --cost=1000

# Adobe Systems Incorporated
# repo --name="Adobe" --baseurl=http://linuxdownload.adobe.com/linux/$basearch/ --cost=1000
# 32bit required for 64bit images also
# repo --name="Adobe-32bit" --baseurl=http://linuxdownload.adobe.com/linux/i386/ --cost=1000

# Other Repositories
repo --name="Google Chrome" --baseurl=http://dl.google.com/linux/chrome/rpm/stable/$basearch/ --cost=1000
repo --name="VirtualBox" --baseurl=http://download.virtualbox.org/virtualbox/rpm/fedora/$releasever/$basearch/ --cost=1000

%packages
# adobe-release
google-chrome-release
# google-earth-release
# google-talkplugin-release
korora-repos
rpmfusion-free-release
rpmfusion-nonfree-release
virtualbox-release
%end
%post

tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/fedora/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

# ### ### ###
: <<'END'
# ### ### ###
tee /etc/yum.repos.d/korora.repo <<-'EOF'
[korora]
name=Korora $releasever - $basearch
#baseurl=http://mirror.linux.org.au/pub/korora/releases/$releasever/$basearch/ ftp://mirror.aarnet.edu.au/pub/korora/korora/releases/$releasever/$basearch/ http://dl.kororaproject.org/pub/korora/releases/$releasever/$basearch/
mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror.lst
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-korora-$releasever-primary
priority=10

[korora-source]
name=Korora $releasever - $basearch - Source
#baseurl=http://mirror.linux.org.au/pub/korora/releases/$releasever/source/ ftp://mirror.aarnet.edu.au/pub/korora/korora/releases/$releasever/source/ http://dl.kororaproject.org/repos/korora/$releasever/source/
mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror-source.lst
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-korora-$releasever-primary
priority=10

[korora-testing]
name=Korora Testing $releasever - $basearch
#baseurl=http://dl.kororaproject.org/pub/korora/testing/$releasever/$basearch/
mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror-testing.lst
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-korora-$releasever-primary
priority=5

[korora-testing-source]
name=Korora Testing $releasever - $basearch - Source
#baseurl=http://dl.kororaproject.org/repos/korora/testing/$releasever/source/
mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror-testing-source.lst
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-korora-$releasever-primary
priority=5
EOF

tee /etc/yum.repos.d/rpmfusion-free.repo <<-'EOF'
[rpmfusion-free]
name=RPM Fusion for Fedora $releasever - Free
#baseurl=http://download1.rpmfusion.org/free/fedora/releases/$releasever/Everything/$basearch/os/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-debuginfo]
name=RPM Fusion for Fedora $releasever - Free - Debug
#baseurl=http://download1.rpmfusion.org/free/fedora/releases/$releasever/Everything/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-source]
name=RPM Fusion for Fedora $releasever - Free - Source
#baseurl=http://download1.rpmfusion.org/free/fedora/releases/$releasever/Everything/source/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever
EOF

tee /etc/yum.repos.d/rpmfusion-free-rawhide.repo <<-'EOF'
[rpmfusion-free-rawhide]
name=RPM Fusion for Fedora Rawhide - Free
#baseurl=http://download1.rpmfusion.org/free/fedora/development/$basearch/os/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-rawhide&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-rawhide

[rpmfusion-free-rawhide-debuginfo]
name=RPM Fusion for Fedora Rawhide - Free - Debug
#baseurl=http://download1.rpmfusion.org/free/fedora/development/$basearch/os/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-rawhide-debug&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-rawhide

[rpmfusion-free-rawhide-source]
name=RPM Fusion for Fedora Rawhide - Free - Source
#baseurl=http://download1.rpmfusion.org/free/fedora/development/source/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-rawhide-source&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-rawhide
EOF

tee /etc/yum.repos.d/rpmfusion-free-updates.repo <<-'EOF'
[rpmfusion-free-updates]
name=RPM Fusion for Fedora $releasever - Free - Updates
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/$releasever/$basearch/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-updates-debuginfo]
name=RPM Fusion for Fedora $releasever - Free - Updates Debug
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/$releasever/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-debug-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-updates-source]
name=RPM Fusion for Fedora $releasever - Free - Updates Source
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/$releasever/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-source-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever
EOF

tee /etc/yum.repos.d/rpmfusion-free-updates-testing.repo <<-'EOF'
[rpmfusion-free-updates-testing]
name=RPM Fusion for Fedora $releasever - Free - Test Updates
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/testing/$releasever/$basearch/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-testing-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-updates-testing-debuginfo]
name=RPM Fusion for Fedora $releasever - Free - Test Updates Debug
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/testing/$releasever/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-testing-debug-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever

[rpmfusion-free-updates-testing-source]
name=RPM Fusion for Fedora $releasever - Free - Test Updates Source
#baseurl=http://download1.rpmfusion.org/free/fedora/updates/testing/$releasever/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-testing-source-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-free-fedora-$releasever
EOF

tee /etc/yum.repos.d/rpmfusion-nonfree.repo <<-'EOF'
[rpmfusion-nonfree]
name=RPM Fusion for Fedora $releasever - Nonfree
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/releases/$releasever/Everything/$basearch/os/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-debuginfo]
name=RPM Fusion for Fedora $releasever - Nonfree - Debug
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/releases/$releasever/Everything/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-source]
name=RPM Fusion for Fedora $releasever - Nonfree - Source
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/releases/$releasever/Everything/source/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever
EOF

tee /etc/yum.repos.d/rpmfusion-nonfree-rawhide.repo <<-'EOF'
[rpmfusion-nonfree-rawhide]
name=RPM Fusion for Fedora Rawhide - Nonfree
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/development/$basearch/os/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-rawhide&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-rawhide

[rpmfusion-nonfree-rawhide-debuginfo]
name=RPM Fusion for Fedora Rawhide - Nonfree - Debug
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/development/$basearch/os/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-rawhide-debug&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-rawhide

[rpmfusion-nonfree-rawhide-source]
name=RPM Fusion for Fedora Rawhide - Nonfree - Source
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/development/source/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-rawhide-source&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-latest file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-rawhide
EOF

tee /etc/yum.repos.d/rpmfusion-nonfree-updates.repo <<-'EOF'
[rpmfusion-nonfree-updates]
name=RPM Fusion for Fedora $releasever - Nonfree - Updates
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-updates-debuginfo]
name=RPM Fusion for Fedora $releasever - Nonfree - Updates Debug
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/$releasever/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-debug-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-updates-source]
name=RPM Fusion for Fedora $releasever - Nonfree - Updates Source
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/$releasever/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-source-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever
EOF

tee /etc/yum.repos.d/rpmfusion-nonfree-updates-testing.repo <<-'EOF'
[rpmfusion-nonfree-updates-testing]
name=RPM Fusion for Fedora $releasever - Nonfree - Test Updates
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/testing/$releasever/$basearch/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-testing-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-updates-testing-debuginfo]
name=RPM Fusion for Fedora $releasever - Nonfree - Test Updates Debug
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/testing/$releasever/$basearch/debug/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-testing-debug-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever

[rpmfusion-nonfree-updates-testing-source]
name=RPM Fusion for Fedora $releasever - Nonfree - Test Updates Source
#baseurl=http://download1.rpmfusion.org/nonfree/fedora/updates/testing/$releasever/SRPMS/
mirrorlist=http://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-testing-source-$releasever&arch=$basearch
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmfusion-nonfree-fedora-$releasever
EOF

# ### ### ###
END
# ### ### ###

repolist='/tmp/repolist.tmp'
dnf --cacheonly --noplugins --quiet repolist all | cut --field=1 --delimiter=' ' | sed 's/^\*//g' | sed --regexp-extended '/^(Using|repo|fedora|updates|korora)$/d' > $repolist
while read -r line || [[ -n "$line" ]]; do
  echo "Disabling $line"
  dnf config-manager --set-disabled $line
done < $repolist
rm $repolist
unset repolist

%end
