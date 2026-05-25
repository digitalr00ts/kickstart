#!/usr/bin/env bash

set -euo pipefail

VARIANT="${1:-server}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

setup_build_context
require_cmd "${QEMU_BINARY}"

if [[ ! -x "tests/test-qemu.sh" ]]; then
  echo "Error: tests/test-qemu.sh not found or not executable"
  exit 1
fi

echo "==> Testing QEMU images..."
./tests/test-qemu.sh "${VARIANT}"
