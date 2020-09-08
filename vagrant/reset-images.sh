#! /usr/bin/env sh

set -e

for BOX in $(vagrant box list | grep -o '^file://boxes/fedora.*\.box') ; do
  vagrant box remove ${BOX} --force
done

for IMAGE in $(sudo virsh vol-list --pool default | grep -o 'file.*fedora.*vagrant.*img '); do
sudo \
  virsh vol-delete \
    --vol "${IMAGE}" \
    --pool default
done

