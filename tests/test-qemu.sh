#!/bin/bash
# test-qemu.sh - Test QEMU-built images
# Launches QEMU VM and runs validation tests

set -e

# Source validation functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/validation.sh"

# Configuration
FEDORA_VERSION="${FEDORA_VERSION:-43}"
VARIANT="${1:-server}"
OUTPUT_DIR="output"
IMAGE_PATH="${OUTPUT_DIR}/${VARIANT}/fedora-${FEDORA_VERSION}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="root"
SSH_PASS="packer"

echo "========================================"
echo "Testing QEMU Image: Fedora ${FEDORA_VERSION} ${VARIANT}"
echo "========================================"

# Check if image exists
if [ ! -f "${IMAGE_PATH}" ]; then
    print_failure "Image not found: ${IMAGE_PATH}"
    echo "Available images:"
    find ${OUTPUT_DIR} -name "*.qcow2" -o -name "fedora-*" 2>/dev/null || echo "No images found"
    exit 1
fi

print_info "Image found: ${IMAGE_PATH}"

# Start QEMU VM in background
print_info "Starting QEMU VM..."

# Create a temporary SSH key for testing if needed
# For now, use password authentication with sshpass if available

QEMU_PID=""

# Launch QEMU
qemu-system-x86_64 \
    -name "test-fedora-${FEDORA_VERSION}-${VARIANT}" \
    -m 2048 \
    -smp 2 \
    -drive file="${IMAGE_PATH}",if=virtio,format=qcow2 \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::${SSH_PORT}-:22 \
    -display none \
    -daemonize \
    -pidfile /tmp/test-qemu-${VARIANT}.pid \
    2>&1

QEMU_PID=$(cat /tmp/test-qemu-${VARIANT}.pid 2>/dev/null || echo "")

if [ -z "${QEMU_PID}" ]; then
    print_failure "Failed to start QEMU VM"
    exit 1
fi

print_success "QEMU VM started (PID: ${QEMU_PID})"

# Cleanup function
cleanup() {
    print_info "Cleaning up..."
    if [ -n "${QEMU_PID}" ] && kill -0 ${QEMU_PID} 2>/dev/null; then
        print_info "Stopping QEMU VM (PID: ${QEMU_PID})..."
        kill ${QEMU_PID} 2>/dev/null || true
        sleep 2
        kill -9 ${QEMU_PID} 2>/dev/null || true
    fi
    rm -f /tmp/test-qemu-${VARIANT}.pid
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Wait for SSH
wait_for_ssh "localhost" "${SSH_PORT}" "${SSH_USER}" 60 || {
    print_failure "Failed to connect to VM via SSH"
    exit 1
}

# Give the system a moment to fully initialize
sleep 5

# Get system information
get_system_info "localhost" "${SSH_PORT}" "${SSH_USER}"

# Run validation tests
check_boot "localhost" "${SSH_PORT}" "${SSH_USER}"
check_ssh "localhost" "${SSH_PORT}" "${SSH_USER}"
check_python "localhost" "${SSH_PORT}" "${SSH_USER}"
check_dnf "localhost" "${SSH_PORT}" "${SSH_USER}"
check_partitions "localhost" "${SSH_PORT}" "${SSH_USER}"
check_lvm "localhost" "${SSH_PORT}" "${SSH_USER}"
check_network "localhost" "${SSH_PORT}" "${SSH_USER}"

# Check for required packages
if [ "${VARIANT}" = "server" ]; then
    check_packages "localhost" "${SSH_PORT}" "${SSH_USER}" \
        sudo curl wget git vim python3
else
    check_packages "localhost" "${SSH_PORT}" "${SSH_USER}" \
        sudo curl wget git vim python3 firefox
fi

# Check services
check_services "localhost" "${SSH_PORT}" "${SSH_USER}" \
    sshd chronyd

# Print summary
print_summary

exit $?
