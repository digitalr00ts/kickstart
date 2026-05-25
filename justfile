set shell := ["bash", "-euo", "pipefail", "-c"]

default:
  @just --list

help:
  @just --list

init:
  @./scripts/init.sh

validate:
  @./scripts/validate.sh

build-server-qemu:
  @./scripts/build-qemu.sh server

build-workstation-qemu:
  @./scripts/build-qemu.sh workstation

build-server-virtualbox:
  @./scripts/build-virtualbox.sh server

build-workstation-virtualbox:
  @./scripts/build-virtualbox.sh workstation

build-all:
  @./scripts/build-all.sh

test-qemu:
  @./scripts/test-qemu.sh

test-virtualbox:
  @./scripts/test-virtualbox.sh

test-all:
  @./scripts/test-all.sh

clean:
  @./scripts/clean.sh

quick:
  @./scripts/build-qemu.sh server

status:
  @./scripts/status.sh
