# MacOS Setup

SPICE is the default GUI backend for non-headless QEMU builds. Install a SPICE-capable QEMU package set:

```sh
brew tap avoidik/qemu-spice
brew install libepoxy-egl --HEAD
brew install virglrenderer --HEAD
brew install qemu-spice

brew tap jeffreywildman/homebrew-virt-manager
brew install virt-viewer
```
