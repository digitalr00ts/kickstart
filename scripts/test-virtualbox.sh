#!/usr/bin/env bash

set -euo pipefail

VARIANT="${1:-server}"

if ! command -v VBoxManage >/dev/null 2>&1; then
  echo "Error: VBoxManage not found. Please install VirtualBox."
  exit 1
fi

if [[ ! -x "tests/test-virtualbox.sh" ]]; then
  echo "Error: tests/test-virtualbox.sh not found or not executable"
  exit 1
fi

echo "==> Testing VirtualBox images..."
./tests/test-virtualbox.sh "${VARIANT}"
