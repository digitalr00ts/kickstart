#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

require_cmd packer
setup_build_context
print_build_context

echo "==> Validating Packer templates..."
read -r -a PACKER_ARGS <<< "$(packer_common_args)"
packer validate "${PACKER_ARGS[@]}" "${PACKER_DIR}/"
echo "==> Validation successful!"
