#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-output}"

echo "==> Cleaning build artifacts..."
rm -rf "${OUTPUT_DIR:?}/"
rm -rf .packer_cache/
rm -f *.box
rm -f *.qcow2
rm -f *.vdi
echo "==> Clean complete!"
