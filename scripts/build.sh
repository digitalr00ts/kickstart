#!/usr/bin/env bash
# Detect the native architecture and use Linux directly or a Lima builder on macOS.
set -euo pipefail

ROOT=$(CDPATH='' cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
VERSION=${1:-44}
ARCH=${2:-$(uname -m)}
NATIVE_ARCH=$(uname -m)
OUTPUT_DIR=${OUTPUT_DIR:-"$ROOT/output"}
LIMA_INSTANCE=${LIMA_INSTANCE:-kiwi-builder}

err() { echo "Error: $*" >&2; exit 1; }
normalize_arch() {
  case "$1" in
    arm64|aarch64) echo aarch64 ;;
    amd64|x86_64) echo x86_64 ;;
    *) err "Unsupported architecture '$1'. Use x86_64 or aarch64." ;;
  esac
}
ARCH=$(normalize_arch "$ARCH")
NATIVE_ARCH=$(normalize_arch "$NATIVE_ARCH")
[[ $ARCH == "$NATIVE_ARCH" ]] || err "Cross-architecture builds are not supported; use a native $ARCH host."
[[ $VERSION =~ ^[0-9]+$ ]] || err 'Version must be numeric.'
[[ -f "$ROOT/kiwi/fedora-$VERSION.kiwi" ]] || err "Missing: kiwi/fedora-$VERSION.kiwi"
mkdir -p -- "$OUTPUT_DIR"
OUTPUT_DIR=$(CDPATH='' cd -- "$OUTPUT_DIR" && pwd)

case "$(uname -s)" in
  Linux)
    cd -- "$ROOT"
    command -v uv >/dev/null || err 'uv not found.'
    export UV_PROJECT_ENVIRONMENT=${UV_PROJECT_ENVIRONMENT:-"$ROOT/.venv"}
    [[ $UV_PROJECT_ENVIRONMENT == /* ]] || UV_PROJECT_ENVIRONMENT="$ROOT/$UV_PROJECT_ENVIRONMENT"
    uv sync --group build --frozen
    kiwi=("$UV_PROJECT_ENVIRONMENT/bin/kiwi-ng")
    if [[ ${EUID:-$(id -u)} != 0 ]]; then kiwi=(sudo -- "${kiwi[@]}"); fi
    "${kiwi[@]}" --type oem --profile "$ARCH" system build \
      --description "$ROOT/kiwi" --target-dir "$OUTPUT_DIR/$ARCH"
    ;;
  Darwin)
    command -v limactl >/dev/null || err 'limactl not found; install Lima.'
    # The guest must see source paths at the same absolute location.
    case "$ROOT/" in "$HOME/"*) ;; *) err 'Place the repository under home for the Lima shared mount.' ;; esac
    listing=$(limactl list --format '{{.Name}} {{.Status}}')
    status=
    while read -r name state; do
      if [[ $name == "$LIMA_INSTANCE" ]]; then status=$state; fi
    done <<< "$listing"
    case "$status" in
      '') limactl start --tty=false --name "$LIMA_INSTANCE" "$ROOT/lima/kiwi-builder.yaml" ;;
      Stopped) limactl start --tty=false "$LIMA_INSTANCE" ;;
      Running) ;;
      *) err "Builder has unsupported status '$status'." ;;
    esac
    guest_output=$(limactl shell "$LIMA_INSTANCE" mktemp -d /opt/kiwi-build/output/build.XXXXXXXX)
    limactl shell --workdir "$ROOT" "$LIMA_INSTANCE" env \
      "OUTPUT_DIR=$guest_output" UV_PROJECT_ENVIRONMENT=/opt/kiwi-build/.venv \
      bash "$ROOT/scripts/build.sh" "$VERSION" "$ARCH"
    mkdir -p -- "$OUTPUT_DIR/$ARCH"
    [[ -z $(find "$OUTPUT_DIR/$ARCH" -mindepth 1 -maxdepth 1 -print -quit) ]] || \
      err "Output is not empty: $OUTPUT_DIR/$ARCH. Guest output retained at $guest_output."
    limactl shell "$LIMA_INSTANCE" sudo bash "$ROOT/scripts/export-image.sh" "$guest_output/$ARCH" | \
      tar -xf - -C "$OUTPUT_DIR/$ARCH"
    limactl shell "$LIMA_INSTANCE" sudo rm -rf -- "$guest_output"
    ;;
  *) err 'Only Linux and macOS build hosts are supported.' ;;
esac
printf 'Artifacts: %s/%s\n' "$OUTPUT_DIR" "$ARCH"
