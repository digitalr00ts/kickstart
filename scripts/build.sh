#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
LIMA_INSTANCE=kiwi-builder
LIMA_TEMPLATE=lima/kiwi-builder.yaml
KIWI_DESC=kiwi/fedora-${VERSION}.kiwi
KIWI_DESC_DIR=${KIWI_DESC%/*}
OUTPUT_DIR=${OUTPUT_DIR:-output}
PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"

err() { echo "Error: $*" >&2; exit 1; }

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64
[[ -f $KIWI_DESC ]] || err "Missing: $KIWI_DESC"
[[ -f $LIMA_TEMPLATE ]] || err "Missing: $LIMA_TEMPLATE"

case "$ARCH" in
  x86_64|aarch64) ;;
  *) err "Unsupported architecture '$ARCH'. Use x86_64 or aarch64." ;;
esac

build() {
  mkdir -p "$OUTPUT_DIR"

  local cmd_prefix=''
  if [[ $PLATFORM == darwin ]]; then
    local cmd_prefix="limactl shell $LIMA_INSTANCE"
  fi

  $cmd_prefix uv sync --group build --frozen
  $cmd_prefix sudo uv run kiwi-ng \
    --type oem \
    --profile "$ARCH" \
    system build \
    --description "$KIWI_DESC_DIR" \
    --target-dir "$OUTPUT_DIR/$ARCH"
}

[[ $PLATFORM == darwin ]] && \
(limactl list | grep "^${LIMA_INSTANCE}" | grep -q "Running" || limactl start --tty=false "$LIMA_TEMPLATE")

build
