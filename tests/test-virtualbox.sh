#!/bin/bash
# test-virtualbox.sh - Test VirtualBox-built images
# Imports VirtualBox VM and runs validation tests

set -e

# Source validation functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/validation.sh"

# Configuration
FEDORA_VERSION="${FEDORA_VERSION:-43}"
VARIANT="${1:-server}"
OUTPUT_DIR="output"
VM_NAME="test-fedora-${FEDORA_VERSION}-${VARIANT}"
SSH_PORT="${SSH_PORT:-2223}"
SSH_USER="root"

echo "========================================"
echo "Testing VirtualBox Image: Fedora ${FEDORA_VERSION} ${VARIANT}"
echo "========================================"

# Check if VBoxManage is available
if ! command -v VBoxManage &> /dev/null; then
    print_failure "VBoxManage not found. Please install VirtualBox."
    exit 1
fi

# Find the OVF/OVA file
OVF_FILE=$(find ${OUTPUT_DIR} -name "*${VARIANT}*.ovf" | head -1)
if [ -z "${OVF_FILE}" ]; then
    print_failure "No OVF file found for ${VARIANT} variant"
    echo "Available files:"
    find ${OUTPUT_DIR} -type f 2>/dev/null || echo "No files found"
    exit 1
fi

print_info "Found OVF: ${OVF_FILE}"

# Cleanup function
cleanup() {
    print_info "Cleaning up..."
    
    # Power off VM if running
    if VBoxManage showvminfo "${VM_NAME}" &>/dev/null; then
        print_info "Powering off VM..."
        VBoxManage controlvm "${VM_NAME}" poweroff 2>/dev/null || true
        sleep 2
        
        # Unregister and delete VM
        print_info "Removing VM..."
        VBoxManage unregistervm "${VM_NAME}" --delete 2>/dev/null || true
    fi
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Remove existing test VM if it exists
cleanup

# Import OVF
print_info "Importing OVF into VirtualBox..."
VBoxManage import "${OVF_FILE}" --vsys 0 --vmname "${VM_NAME}" || {
    print_failure "Failed to import OVF"
    exit 1
}

# Configure port forwarding for SSH
print_info "Configuring network (SSH port forwarding)..."
VBoxManage modifyvm "${VM_NAME}" \
    --natpf1 "ssh,tcp,,${SSH_PORT},,22" || {
    print_failure "Failed to configure port forwarding"
    exit 1
}

# Start VM
print_info "Starting VirtualBox VM..."
VBoxManage startvm "${VM_NAME}" --type headless || {
    print_failure "Failed to start VM"
    exit 1
}

print_success "VirtualBox VM started"

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

# Check VirtualBox Guest Additions
print_info "Checking for VirtualBox Guest Additions..."
if ssh -o StrictHostKeyChecking=no -p ${SSH_PORT} ${SSH_USER}@localhost \
       "lsmod | grep vbox" 2>/dev/null | grep -q "vbox"; then
    print_success "VirtualBox Guest Additions detected"
else
    print_warning "VirtualBox Guest Additions not detected (may need to be installed)"
fi

# Print summary
print_summary

exit $?
