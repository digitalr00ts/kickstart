#!/bin/bash
# test-qemu.sh - Test QEMU-built images
# Launches QEMU VM and runs validation tests

set -e

# Source validation functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/validation.sh"

# Configuration
VARIANT="${1:-server}"
OUTPUT_DIR="output"
FEDORA_VERSION="${FEDORA_VERSION:-44}"
HOST_ARCH_RAW="$(uname -m)"
if [ "${HOST_ARCH_RAW}" = "arm64" ] || [ "${HOST_ARCH_RAW}" = "aarch64" ]; then
    DEFAULT_GUEST_ARCH="aarch64"
else
    DEFAULT_GUEST_ARCH="x86_64"
fi
GUEST_ARCH="${GUEST_ARCH:-${DEFAULT_GUEST_ARCH}}"
QEMU_BINARY="${QEMU_BINARY:-qemu-system-${GUEST_ARCH}}"

IMAGE_PATH="${OUTPUT_DIR}/qemu-${GUEST_ARCH}-${VARIANT}/fedora-${FEDORA_VERSION}-${GUEST_ARCH}-${VARIANT}"
LEGACY_IMAGE_PATH="${OUTPUT_DIR}/${VARIANT}/fedora-${VARIANT}"
LEGACY_IMAGE_PATH_V2="${OUTPUT_DIR}/qemu-${VARIANT}/fedora-${FEDORA_VERSION}-${VARIANT}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="root"
# SSH_PASS is set for documentation but authentication is handled by SSH keys
# shellcheck disable=SC2034
SSH_PASS="packer"

echo "========================================"
echo "Testing QEMU Image: Fedora ${VARIANT}"
echo "========================================"

# Check if image exists
if [ ! -f "${IMAGE_PATH}" ]; then
    if [ -f "${LEGACY_IMAGE_PATH_V2}" ]; then
        IMAGE_PATH="${LEGACY_IMAGE_PATH_V2}"
    elif [ -f "${LEGACY_IMAGE_PATH}" ]; then
        IMAGE_PATH="${LEGACY_IMAGE_PATH}"
    fi
fi

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
QEMU_EXTRA_ARGS=()
if [ "${GUEST_ARCH}" = "aarch64" ]; then
    QEMU_EXTRA_ARGS=(
        -machine virt
        -cpu max
    )
fi

"${QEMU_BINARY}" \
    -name "test-fedora-${VARIANT}" \
    -m 2048 \
    -smp 2 \
    "${QEMU_EXTRA_ARGS[@]}" \
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
