#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
LIMA_INSTANCE=kiwi-builder
LIMA_TEMPLATE=lima/kiwi-builder.yaml

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64

KIWI_DESC=kiwi/fedora-${VERSION}-minimal.kiwi
OUTPUT_DIR=output/kiwi-${ARCH}

err() { echo "Error: $*" >&2; exit 1; }

[[ -f $KIWI_DESC ]] || err "Missing: $KIWI_DESC"
[[ -f kiwi/config.sh ]] || err "Missing: kiwi/config.sh"
[[ -f $LIMA_TEMPLATE ]] || err "Missing: $LIMA_TEMPLATE"

case $(uname -s) in
  Darwin) PLATFORM=macos; command -v limactl &>/dev/null || err "Lima required: brew install lima" ;;
  Linux) PLATFORM=linux; command -v kiwi-ng &>/dev/null || err "Kiwi required: sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps" ;;
  *) err "Unsupported: $(uname -s)" ;;
esac

setup_lima() {
  [[ $PLATFORM != macos ]] && return
  limactl list | grep -q "^${LIMA_INSTANCE}" || limactl create --name="$LIMA_INSTANCE" "$LIMA_TEMPLATE"
  limactl list | grep "^${LIMA_INSTANCE}" | grep -q "Running" || limactl start "$LIMA_INSTANCE"
  limactl shell "$LIMA_INSTANCE" command -v kiwi-ng &>/dev/null || \
    limactl shell "$LIMA_INSTANCE" sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
}

build() {
  mkdir -p "$OUTPUT_DIR"
  [[ $PLATFORM == macos ]] && \
    limactl shell "$LIMA_INSTANCE" sudo kiwi-ng --type oem system build --description "$(pwd)/${KIWI_DESC%/*}" --target-dir "$(pwd)/$OUTPUT_DIR" || \
    sudo kiwi-ng --type oem system build --description "${KIWI_DESC%/*}" --target-dir "$OUTPUT_DIR"
}

setup_lima
build
