[![Build Status](https://travis-ci.org/digitalr00ts/korora-kickstart.svg?branch=master)](https://travis-ci.org/digitalr00ts/korora-kickstart)

# korora-kickstart
The digitalr00ts Fedora spins.

Workstation builds built on Korora kickstart files for my various deployments our for end users.

Korora Fedora at its core with several additions, namely RPM Fusion repositories, Korora customizations, and select pre-installed packages.
We have gone and tailored it further for my use cases and preferences.

Currently these kickstart files are intended for use with down
The builds are intended for use with online or local repositories,
but not composed for building live distribution disks.

## MIN.CFG
Minimal setup - Generic

## BASE.CFG
Basic tools and cli - Korora
Common base for server and desktop deployments

## BASE-X.CFG
Installs X11 and basic configuration for GUI deployments

## XFCE-MIN.CFG
Installs XFCE, but no applications.

## Xfce Desktop
A customized Korora Xfce Desktop which is the bases for the other variants.

### To Do
* Create git hosted kickstart cfg
* Change default theme
* Add branding
* Change PCManFM settings
* Add uBlock Origin for Chrome

#### Related Projects
* Docker repositories RPM
* Atom RPM in RPM Fussion

## Kodi
Coming Soon
