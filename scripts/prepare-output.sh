#!/bin/bash
# prepare-output.sh - Prepare output directory structure
# Creates organized directories for build artifacts

set -e

# Default output directory
OUTPUT_DIR="${1:-output}"

echo "==> Preparing output directory: ${OUTPUT_DIR}"

# Create main output directory
mkdir -p "${OUTPUT_DIR}"

# Create subdirectories for different platforms and variants
mkdir -p "${OUTPUT_DIR}/qemu/server"
mkdir -p "${OUTPUT_DIR}/qemu/workstation"
mkdir -p "${OUTPUT_DIR}/virtualbox/server"
mkdir -p "${OUTPUT_DIR}/virtualbox/workstation"

# Create directory for Vagrant boxes if needed
mkdir -p "${OUTPUT_DIR}/vagrant"

# Create directory for logs
mkdir -p "${OUTPUT_DIR}/logs"

echo "==> Output directory structure created:"
tree -L 3 "${OUTPUT_DIR}" 2>/dev/null || find "${OUTPUT_DIR}" -type d

echo "==> Output directory prepared successfully!"
