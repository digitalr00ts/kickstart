#!/bin/bash
# cleanup.sh - Pre-build cleanup operations
# Removes stale build artifacts and prepares for a clean build

set -e

echo "==> Starting cleanup operations..."

# Remove output directory
if [ -d "output" ]; then
    echo "Removing output directory..."
    rm -rf output/
fi

# Remove Packer cache
if [ -d ".packer_cache" ]; then
    echo "Removing Packer cache..."
    rm -rf .packer_cache/
fi

# Remove any stray box files
if ls *.box 1> /dev/null 2>&1; then
    echo "Removing box files..."
    rm -f *.box
fi

# Remove any stray QEMU images
if ls *.qcow2 1> /dev/null 2>&1; then
    echo "Removing qcow2 images..."
    rm -f *.qcow2
fi

# Remove any stray VirtualBox images
if ls *.vdi 1> /dev/null 2>&1; then
    echo "Removing VDI images..."
    rm -f *.vdi
fi

# Clean Ansible fact cache if it exists
if [ -d "/tmp/ansible_fact_cache" ]; then
    echo "Cleaning Ansible fact cache..."
    rm -rf /tmp/ansible_fact_cache
fi

echo "==> Cleanup complete!"
