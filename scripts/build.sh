#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
LIMA_INSTANCE=kiwi-builder
LIMA_TEMPLATE=lima/kiwi-builder.yaml
KIWI_DESC=kiwi/fedora-${VERSION}.kiwi
KIWI_DESC_DIR=${KIWI_DESC%/*}
KIWI_PROFILE=$ARCH
OUTPUT_DIR=output/kiwi-${ARCH}

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64

err() { echo "Error: $*" >&2; exit 1; }

case "$ARCH" in
  x86_64|aarch64) ;;
  *)
    err "Unsupported architecture '$ARCH'. Use x86_64 or aarch64."
    ;;
esac

[[ -f $KIWI_DESC ]] || err "Missing: $KIWI_DESC"
[[ -f $LIMA_TEMPLATE ]] || err "Missing: $LIMA_TEMPLATE"

case $(uname -s) in
  Darwin) PLATFORM=macos; command -v limactl &>/dev/null || err "Lima required: brew install lima" ;;
  Linux) PLATFORM=linux; command -v kiwi-ng &>/dev/null || err "Kiwi required: uv sync --group build && sudo dnf install -y kiwi-systemdeps" ;;
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
  if [[ $PLATFORM == macos ]]; then
    limactl shell "$LIMA_INSTANCE" sudo kiwi-ng --type oem --profile "$KIWI_PROFILE" system build --description "$(pwd)/$KIWI_DESC_DIR" --target-dir "$(pwd)/$OUTPUT_DIR"
  else
    sudo kiwi-ng --type oem --profile "$KIWI_PROFILE" system build --description "$KIWI_DESC_DIR" --target-dir "$OUTPUT_DIR"
  fi
}

setup_lima
build
