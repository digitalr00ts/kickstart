#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Building all variants..."
"${SCRIPT_DIR}/build-qemu.sh" server
"${SCRIPT_DIR}/build-qemu.sh" workstation

if command -v VBoxManage >/dev/null 2>&1; then
  "${SCRIPT_DIR}/build-virtualbox.sh" server
  "${SCRIPT_DIR}/build-virtualbox.sh" workstation
else
  echo "Skipping VirtualBox builds (VirtualBox not installed)"
fi
