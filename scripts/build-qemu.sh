#!/usr/bin/env bash

set -euo pipefail

VARIANT="${1:-server}"

if [[ "${VARIANT}" != "server" && "${VARIANT}" != "workstation" ]]; then
  echo "Error: variant must be server or workstation"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd packer
require_cmd ansible-playbook
setup_build_context
require_cmd "${QEMU_BINARY}"
print_build_context

echo "==> Building Fedora ${FEDORA_VERSION} ${VARIANT} for QEMU..."
read -r -a PACKER_ARGS <<< "$(packer_common_args)"
packer build -only=qemu.fedora "${PACKER_ARGS[@]}" -var "variant=${VARIANT}" "${PACKER_DIR}/"
