# MacOS Setup

Non-headless QEMU builds default to Cocoa on macOS.

```sh
brew install qemu
```

If you want SPICE explicitly on macOS, install a SPICE-capable QEMU package set:

```sh
brew tap avoidik/qemu-spice
brew install libepoxy-egl --HEAD
brew install virglrenderer --HEAD
brew install qemu-spice

brew tap jeffreywildman/homebrew-virt-manager
brew install virt-viewer
```
