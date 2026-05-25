#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Running all tests..."
"${SCRIPT_DIR}/test-qemu.sh"

if command -v VBoxManage >/dev/null 2>&1; then
  "${SCRIPT_DIR}/test-virtualbox.sh"
else
  echo "Skipping VirtualBox tests (VirtualBox not installed)"
fi
