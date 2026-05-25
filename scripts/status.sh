#!/usr/bin/env bash

set -euo pipefail

OUTPUT_DIR="${OUTPUT_DIR:-output}"

echo "==> Build Status"
echo
echo "Output directory: ${OUTPUT_DIR}"
if [[ -d "${OUTPUT_DIR}" ]]; then
  echo "Artifacts:"
  ls -lh "${OUTPUT_DIR}/"
else
  echo "No build artifacts found."
fi
echo
echo "Packer cache:"
if [[ -d ".packer_cache" ]]; then
  du -sh .packer_cache/
else
  echo "No Packer cache."
fi
