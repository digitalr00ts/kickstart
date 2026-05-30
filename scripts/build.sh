#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
LIMA_INSTANCE=kiwi-builder

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64

KIWI_DESC=kiwi/fedora-${VERSION}-minimal.kiwi
OUTPUT_DIR=output/kiwi-${ARCH}

err() { echo "Error: $*" >&2; exit 1; }

[[ -f $KIWI_DESC ]] || err "Missing: $KIWI_DESC"
[[ -f kiwi/config.sh ]] || err "Missing: kiwi/config.sh"

case $(uname -s) in
  Darwin)
    PLATFORM=macos
    command -v limactl &>/dev/null || err "Lima required: brew install lima"
    ;;
  Linux)
    PLATFORM=linux
    command -v kiwi-ng &>/dev/null || err "Kiwi required: sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps"
    ;;
  *) err "Unsupported: $(uname -s)" ;;
esac

setup_lima() {
  [[ $PLATFORM != macos ]] && return

  if ! limactl list | grep -q "^${LIMA_INSTANCE}"; then
    cat > /tmp/lima-kiwi.yaml <<EOF
arch: "default"
images:
  - location: "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/aarch64/images/Fedora-Cloud-Base-Generic-43-1.6.aarch64.qcow2"
    arch: "aarch64"
  - location: "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
    arch: "x86_64"
cpus: 4
memory: "8GiB"
disk: "50GiB"
mounts:
  - location: "~"
    writable: true
  - location: "/tmp/lima"
    writable: true
containerd:
  system: false
  user: false
provision:
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
EOF
    limactl create --name="$LIMA_INSTANCE" /tmp/lima-kiwi.yaml
    rm /tmp/lima-kiwi.yaml
  fi

  limactl list | grep "^${LIMA_INSTANCE}" | grep -q "Running" || limactl start "$LIMA_INSTANCE"
  limactl shell "$LIMA_INSTANCE" command -v kiwi-ng &>/dev/null || \
    limactl shell "$LIMA_INSTANCE" sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
}

build() {
  mkdir -p "$OUTPUT_DIR"

  if [[ $PLATFORM == macos ]]; then
    limactl shell "$LIMA_INSTANCE" sudo kiwi-ng --type oem system build \
      --description "$(pwd)/${KIWI_DESC%/*}" --target-dir "$(pwd)/$OUTPUT_DIR"
  else
    sudo kiwi-ng --type oem system build --description "${KIWI_DESC%/*}" --target-dir "$OUTPUT_DIR"
  fi
}

show_results() {
  [[ -d $OUTPUT_DIR ]] || err "Output dir not found"

  echo "Output:"
  for f in "$OUTPUT_DIR"/*; do
    [[ -f $f ]] && printf "  %s (%s)\n" "$(basename "$f")" "$(du -h "$f" | cut -f1)"
  done

  img=$(find "$OUTPUT_DIR" -name "*.qcow2" | head -n1)
  [[ -n $img ]] && cat <<EOF

Image: $img

Next: uv run poe provision
Test: uv run poe test qemu
Boot: qemu-system-${ARCH} -m 2048 -smp 2 -drive file=$img,format=qcow2
EOF
}

setup_lima
build
show_results
