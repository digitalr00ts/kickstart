#!/usr/bin/env bash
# Apply Ansible provisioning to a Kiwi-built image
# This script boots the image in QEMU and runs Ansible against it

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_PATH="${1:-}"
ARCH="${2:-$(uname -m)}"
SSH_PORT="${SSH_PORT:-2222}"
SSH_USER="${SSH_USER:-vagrant}"
SSH_PASS="${SSH_PASS:-vagrant}"
ANSIBLE_PLAYBOOK="${ANSIBLE_PLAYBOOK:-ansible/playbook.yml}"
ANSIBLE_REQUIREMENTS="${ANSIBLE_REQUIREMENTS:-ansible/requirements.yml}"

# Normalize architecture
case "$ARCH" in
    arm64) ARCH="aarch64" ;;
    amd64) ARCH="x86_64" ;;
esac

QEMU_BINARY="qemu-system-${ARCH}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Ansible Provisioning for Kiwi Images              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

#======================================
# Validate prerequisites
#======================================
validate_prerequisites() {
    echo -e "${BLUE}→${NC} Validating prerequisites..."

    if [ -z "$IMAGE_PATH" ]; then
        echo -e "${RED}✗ Error: Image path not provided${NC}"
        echo -e "${YELLOW}Usage: $0 <image-path> [architecture]${NC}"
        exit 1
    fi

    if [ ! -f "$IMAGE_PATH" ]; then
        echo -e "${RED}✗ Error: Image not found: ${IMAGE_PATH}${NC}"
        exit 1
    fi

    if ! command -v "$QEMU_BINARY" &> /dev/null; then
        echo -e "${RED}✗ Error: ${QEMU_BINARY} not found${NC}"
        exit 1
    fi

    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}✗ Error: ansible-playbook not found${NC}"
        echo -e "${YELLOW}Install with: pip install ansible${NC}"
        exit 1
    fi

    if [ ! -f "$ANSIBLE_PLAYBOOK" ]; then
        echo -e "${RED}✗ Error: Ansible playbook not found: ${ANSIBLE_PLAYBOOK}${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Prerequisites validated"
}

#======================================
# Create working copy of image
#======================================
create_working_copy() {
    echo -e "${BLUE}→${NC} Creating working copy of image..."

    WORKING_IMAGE=$(mktemp -u).qcow2
    cp "$IMAGE_PATH" "$WORKING_IMAGE"

    echo -e "${GREEN}✓${NC} Working copy created: ${WORKING_IMAGE}"
}

#======================================
# Detect if we should use Lima
#======================================
should_use_lima() {
    local host_arch
    host_arch="$(uname -m)"

    # Only consider Lima on macOS
    [[ "$(uname -s)" != "Darwin" ]] && return 1

    # Check if architectures match
    if [[ "$host_arch" == "$ARCH" ]] || [[ "$host_arch" == "arm64" && "$ARCH" == "aarch64" ]]; then
        # Native architecture - HVF is fastest
        return 1
    fi

    # Cross-architecture - Lima with KVM is much faster than TCG
    if command -v limactl &> /dev/null; then
        echo -e "${YELLOW}Cross-architecture detected, using Lima for better performance${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Warning: Cross-architecture without Lima - using slow TCG emulation${NC}"
        echo -e "${YELLOW}  Install Lima for much faster provisioning: brew install lima${NC}"
        return 1
    fi
}

#======================================
# Start QEMU instance (native or Lima)
#======================================
start_qemu() {
    echo -e "${BLUE}→${NC} Starting QEMU instance..."
    echo -e "  Image: ${YELLOW}${WORKING_IMAGE}${NC}"
    echo -e "  SSH Port: ${YELLOW}${SSH_PORT}${NC}"

    if should_use_lima; then
        start_qemu_lima
    else
        start_qemu_native
    fi
}

#======================================
# Start QEMU natively (with HVF/KVM/TCG)
#======================================
start_qemu_native() {
    # Determine QEMU acceleration
    if [[ "$(uname -s)" == "Darwin" ]]; then
        ACCEL="-accel hvf"
        echo -e "  Acceleration: ${YELLOW}HVF (native macOS)${NC}"
    elif [[ -e /dev/kvm ]]; then
        ACCEL="-accel kvm"
        echo -e "  Acceleration: ${YELLOW}KVM (native Linux)${NC}"
    else
        ACCEL="-accel tcg"
        echo -e "  Acceleration: ${YELLOW}TCG (emulation - slow)${NC}"
    fi

    # Start QEMU in background
    $QEMU_BINARY \
        $ACCEL \
        -m 2048 \
        -smp 2 \
        -drive file="${WORKING_IMAGE}",format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp::${SSH_PORT}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -nographic \
        -serial mon:stdio \
        > /tmp/qemu-provision-$$.log 2>&1 &

    QEMU_PID=$!
    USE_LIMA=false
    echo -e "${GREEN}✓${NC} QEMU started (PID: ${QEMU_PID})"

    # Ensure cleanup on exit
    trap "cleanup_qemu" EXIT INT TERM
}

#======================================
# Start QEMU via Lima (for cross-arch)
#======================================
start_qemu_lima() {
    echo -e "  Method: ${YELLOW}Lima (Linux VM with KVM)${NC}"

    # Ensure Lima instance exists
    if ! limactl list | grep -q "^provision-vm"; then
        echo -e "${BLUE}→${NC} Creating Lima VM for provisioning..."
        limactl start --name=provision-vm template://default
    fi

    # Copy image to Lima
    echo -e "${BLUE}→${NC} Copying image to Lima VM..."
    limactl copy "${WORKING_IMAGE}" provision-vm:/tmp/provision-image.qcow2

    # Start QEMU inside Lima
    limactl shell provision-vm qemu-system-${ARCH} \
        -accel kvm \
        -m 2048 \
        -smp 2 \
        -drive file=/tmp/provision-image.qcow2,format=qcow2,if=virtio \
        -netdev user,id=net0,hostfwd=tcp:0.0.0.0:${SSH_PORT}-:22 \
        -device virtio-net-pci,netdev=net0 \
        -nographic \
        -daemonize \
        -pidfile /tmp/qemu-provision.pid

    QEMU_PID=$(limactl shell provision-vm cat /tmp/qemu-provision.pid)
    USE_LIMA=true
    echo -e "${GREEN}✓${NC} QEMU started in Lima VM (PID: ${QEMU_PID})"

    # Ensure cleanup on exit
    trap "cleanup_qemu" EXIT INT TERM
}

#======================================
# Wait for SSH to be available
#======================================
wait_for_ssh() {
    echo -e "${BLUE}→${NC} Waiting for SSH to be available..."

    local max_attempts=60
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if nc -z localhost $SSH_PORT 2>/dev/null; then
            echo -e "${GREEN}✓${NC} SSH is available"
            sleep 5  # Wait a bit more for sshd to be fully ready
            return 0
        fi

        echo -ne "\r  Attempt $((attempt+1))/${max_attempts}..."
        sleep 2
        attempt=$((attempt+1))
    done

    echo -e "\n${RED}✗ Timeout waiting for SSH${NC}"
    return 1
}

#======================================
# Run Ansible provisioning
#======================================
run_ansible() {
    echo -e "${BLUE}→${NC} Running Ansible provisioning..."
    echo ""

    # Install Ansible collections if requirements file exists
    if [ -f "$ANSIBLE_REQUIREMENTS" ]; then
        echo -e "${YELLOW}Installing Ansible collections...${NC}"
        ansible-galaxy collection install -r "$ANSIBLE_REQUIREMENTS"
    fi

    # Run Ansible playbook
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i "localhost:${SSH_PORT}," \
        -e "ansible_user=${SSH_USER}" \
        -e "ansible_ssh_pass=${SSH_PASS}" \
        -e "ansible_connection=ssh" \
        -e "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'" \
        "$ANSIBLE_PLAYBOOK"

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✓${NC} Ansible provisioning completed successfully"
    else
        echo ""
        echo -e "${RED}✗${NC} Ansible provisioning failed"
        return 1
    fi
}

#======================================
# Shutdown QEMU gracefully
#======================================
shutdown_qemu() {
    echo -e "${BLUE}→${NC} Shutting down QEMU..."

    # Try to shutdown gracefully via SSH
    sshpass -p "$SSH_PASS" ssh \
        -p $SSH_PORT \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        ${SSH_USER}@localhost \
        "sudo poweroff" 2>/dev/null || true

    # Wait for QEMU to exit
    local timeout=30
    local elapsed=0

    if [[ "${USE_LIMA:-false}" == "true" ]]; then
        # Check if QEMU in Lima is still running
        while limactl shell provision-vm test -e /proc/$QEMU_PID 2>/dev/null && [ $elapsed -lt $timeout ]; do
            sleep 1
            elapsed=$((elapsed+1))
        done

        # Force kill if still running
        if limactl shell provision-vm test -e /proc/$QEMU_PID 2>/dev/null; then
            echo -e "${YELLOW}Force killing QEMU in Lima...${NC}"
            limactl shell provision-vm kill -9 $QEMU_PID 2>/dev/null || true
        fi
    else
        # Native QEMU shutdown
        while kill -0 $QEMU_PID 2>/dev/null && [ $elapsed -lt $timeout ]; do
            sleep 1
            elapsed=$((elapsed+1))
        done

        # Force kill if still running
        if kill -0 $QEMU_PID 2>/dev/null; then
            echo -e "${YELLOW}Force killing QEMU...${NC}"
            kill -9 $QEMU_PID 2>/dev/null || true
        fi
    fi

    echo -e "${GREEN}✓${NC} QEMU shutdown"
}

#======================================
# Replace original image with provisioned one
#======================================
replace_image() {
    echo -e "${BLUE}→${NC} Replacing original image..."

    if [[ "${USE_LIMA:-false}" == "true" ]]; then
        # Copy image back from Lima
        limactl copy provision-vm:/tmp/provision-image.qcow2 "${WORKING_IMAGE}"
    fi

    mv "$WORKING_IMAGE" "$IMAGE_PATH"

    echo -e "${GREEN}✓${NC} Image updated: ${IMAGE_PATH}"
}

#======================================
# Cleanup function
#======================================
cleanup_qemu() {
    if [ -n "${QEMU_PID:-}" ]; then
        echo ""
        echo -e "${YELLOW}Cleaning up QEMU process...${NC}"

        if [[ "${USE_LIMA:-false}" == "true" ]]; then
            limactl shell provision-vm kill -9 $QEMU_PID 2>/dev/null || true
            limactl shell provision-vm rm -f /tmp/provision-image.qcow2 2>/dev/null || true
        else
            kill -9 $QEMU_PID 2>/dev/null || true
        fi
    fi

    # Clean up working copy if it still exists and wasn't moved
    if [ -n "${WORKING_IMAGE:-}" ] && [ -f "$WORKING_IMAGE" ]; then
        rm -f "$WORKING_IMAGE"
    fi
}

#======================================
# Main execution
#======================================
main() {
    validate_prerequisites
    create_working_copy
    start_qemu

    if wait_for_ssh; then
        if run_ansible; then
            shutdown_qemu
            replace_image

            echo ""
            echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
            echo -e "${GREEN}Provisioning completed successfully!${NC}"
            echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
            return 0
        else
            echo -e "${RED}Provisioning failed${NC}"
            return 1
        fi
    else
        echo -e "${RED}Failed to connect to VM${NC}"
        return 1
    fi
}

# Run main function
main
exit $?
