# REPOS

# Fedora
# repo --name=fedora-mirrors --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
# repo --name="fedora-updates" --mirrorlist=http://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
repo --name="Fedora-Everything" --baseurl=http://dl.fedoraproject.org/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/ --cost=1000
repo --name="Fedora-Update" --baseurl=http://dl.fedoraproject.org/pub/fedora/linux/updates/$releasever/$basearch/ --cost=1000

# Korora
# repo --name="Korora" --mirrorlist=http://dl.kororaproject.org/pub/korora/korora-mirror.lst --cost=10
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
# repo --name="VirtualBox" --baseurl=http://download.virtualbox.org/virtualbox/rpm/fedora/$releasever/$basearch/ --cost=1000
