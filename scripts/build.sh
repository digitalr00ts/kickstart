#!/usr/bin/env bash
set -euo pipefail

VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
KIWI_DESC=kiwi/fedora-${VERSION}.kiwi
KIWI_DESC_DIR=${KIWI_DESC%/*}
OUTPUT_DIR=${OUTPUT_DIR:-output}
PLATFORM="$(uname -s | tr '[:upper:]' '[:lower:]')"

err() { echo "Error: $*" >&2; exit 1; }

check-lima(){
  [[ ! $PLATFORM == darwin ]] && return
  local status
  status="$(poe lima-cmd list -- --format '{{.Status}}')" || true
  [[ -n "${status}" ]] || { poe lima-create; return; }
  [[ "${status}" = "Stopped" ]] && poe lima-cmd start || true
  OUTPUT_DIR=/opt/kiwi-build/output/
}

prefix() {
  [[ ! $PLATFORM == darwin ]] && return
  command -v limactl >/dev/null || err limactl not found.
  echo "poe lima-cmd shell --"
}

build() {
  local cmd_prefix
  cmd_prefix=$($1)

  # shellcheck disable=SC2068
  ${cmd_prefix[@]} mkdir -p "$OUTPUT_DIR"
  # shellcheck disable=SC2068
  ${cmd_prefix[@]} uv sync --group build --frozen
  # shellcheck disable=SC2068
  ${cmd_prefix[@]} sudo uv run kiwi-ng \
    --type oem \
    --profile "$ARCH" \
    system build \
    --description "$KIWI_DESC_DIR" \
    --target-dir "$OUTPUT_DIR/$ARCH"
}

[[ $ARCH == arm64 ]] && ARCH=aarch64
[[ $ARCH == amd64 ]] && ARCH=x86_64
[[ -f $KIWI_DESC ]] || err "Missing: $KIWI_DESC"

case "$ARCH" in
  x86_64|aarch64) ;;
  *) err "Unsupported architecture '$ARCH'. Use x86_64 or aarch64." ;;
esac

check-lima
build prefix
