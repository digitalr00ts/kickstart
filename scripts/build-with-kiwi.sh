#!/usr/bin/env bash
# Build Fedora images using Kiwi NG
# Automatically uses Lima on macOS or native Kiwi on Linux

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="${1:-44}"
ARCH="${2:-$(uname -m)}"
KIWI_DESC="kiwi/fedora-${VERSION}-minimal.kiwi"
OUTPUT_DIR="output/kiwi-${ARCH}"
LIMA_INSTANCE="kiwi-builder"

# Normalize architecture names
case "$ARCH" in
    arm64) ARCH="aarch64" ;;
    amd64) ARCH="x86_64" ;;
esac

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Fedora Image Builder - Kiwi NG Edition            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Configuration:${NC}"
echo -e "  Version:     ${YELLOW}Fedora ${VERSION}${NC}"
echo -e "  Architecture: ${YELLOW}${ARCH}${NC}"
echo -e "  Description: ${YELLOW}${KIWI_DESC}${NC}"
echo -e "  Output:      ${YELLOW}${OUTPUT_DIR}${NC}"
echo ""

#======================================
# Validate prerequisites
#======================================
validate_prerequisites() {
    echo -e "${BLUE}→${NC} Validating prerequisites..."

    if [ ! -f "$KIWI_DESC" ]; then
        echo -e "${RED}✗ Error: Kiwi description not found: ${KIWI_DESC}${NC}"
        exit 1
    fi

    if [ ! -f "kiwi/config.sh" ]; then
        echo -e "${RED}✗ Error: Configuration script not found: kiwi/config.sh${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓${NC} Prerequisites validated"
}

#======================================
# Detect platform and setup environment
#======================================
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo -e "${YELLOW}🍎 macOS detected - will use Lima VM${NC}"
            PLATFORM="macos"

            # Check if Lima is installed
            if ! command -v limactl &> /dev/null; then
                echo -e "${RED}✗ Error: Lima is not installed${NC}"
                echo -e "${YELLOW}Install with: brew install lima${NC}"
                exit 1
            fi
            ;;
        Linux*)
            echo -e "${GREEN}🐧 Linux detected - will use native Kiwi${NC}"
            PLATFORM="linux"

            # Check if Kiwi is installed
            if ! command -v kiwi-ng &> /dev/null; then
                echo -e "${RED}✗ Error: Kiwi NG is not installed${NC}"
                echo -e "${YELLOW}Install with: sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}✗ Unsupported platform: $(uname -s)${NC}"
            exit 1
            ;;
    esac
}

#======================================
# Setup Lima VM (macOS only)
#======================================
setup_lima() {
    if [ "$PLATFORM" != "macos" ]; then
        return
    fi

    echo -e "${BLUE}→${NC} Setting up Lima VM..."

    # Check if Lima instance exists
    if ! limactl list | grep -q "^${LIMA_INSTANCE}"; then
        echo -e "${YELLOW}Creating Lima instance '${LIMA_INSTANCE}' with writable mounts...${NC}"

        # Create temporary Lima config with writable mounts
        LIMA_CONFIG=$(mktemp)
        cat > "$LIMA_CONFIG" <<EOF
# Lima configuration for Kiwi NG builds
# Based on Fedora template with writable project directory
arch: "default"
images:
  - location: "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/aarch64/images/Fedora-Cloud-Base-Generic-43-1.6.aarch64.qcow2"
    arch: "aarch64"
  - location: "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2"
    arch: "x86_64"

cpus: 4
memory: "8GiB"
disk: "50GiB"

# Writable mounts for Kiwi NG
mounts:
  - location: "~"
    writable: true
  - location: "/tmp/lima"
    writable: true

containerd:
  system: false
  user: false

provision:
  - mode: system
    script: |
      #!/bin/bash
      set -eux -o pipefail
      dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
EOF

        # Create Lima instance with custom config
        limactl create --name="${LIMA_INSTANCE}" "$LIMA_CONFIG"

        rm -f "$LIMA_CONFIG"
        echo -e "${GREEN}✓${NC} Lima instance created with writable mounts"
    fi

    # Start Lima instance if not running
    if ! limactl list | grep "^${LIMA_INSTANCE}" | grep -q "Running"; then
        echo -e "${YELLOW}Starting Lima instance...${NC}"
        limactl start "${LIMA_INSTANCE}"
    fi

    echo -e "${GREEN}✓${NC} Lima VM is ready"

    # Install Kiwi NG in Lima if not present
    echo -e "${BLUE}→${NC} Checking Kiwi NG installation in Lima..."
    if ! limactl shell "${LIMA_INSTANCE}" command -v kiwi-ng &> /dev/null; then
        echo -e "${YELLOW}Installing Kiwi NG in Lima VM (this may take a few minutes)...${NC}"
        limactl shell "${LIMA_INSTANCE}" sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
        echo -e "${GREEN}✓${NC} Kiwi NG installed"
    else
        echo -e "${GREEN}✓${NC} Kiwi NG already installed"
    fi
}

#======================================
# Build image with Kiwi NG
#======================================
build_image() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                    Building Base Image                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    if [ "$PLATFORM" = "macos" ]; then
        echo -e "${YELLOW}Building in Lima VM...${NC}"
        echo ""

        # Run Kiwi in Lima VM
        # Note: Lima automatically mounts the home directory, so we can access project files
        limactl shell "${LIMA_INSTANCE}" sudo kiwi-ng \
            --type oem \
            system build \
            --description "$(pwd)/${KIWI_DESC%/*}" \
            --target-dir "$(pwd)/${OUTPUT_DIR}"

    else
        echo -e "${YELLOW}Building natively...${NC}"
        echo ""

        # Run Kiwi directly
        sudo kiwi-ng \
            --type oem \
            system build \
            --description "${KIWI_DESC%/*}" \
            --target-dir "${OUTPUT_DIR}"
    fi

    echo ""
    echo -e "${GREEN}✓${NC} Base image built successfully"
}

#======================================
# Display results
#======================================
display_results() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                       Build Complete                       ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ -d "$OUTPUT_DIR" ]; then
        echo -e "${GREEN}Output files:${NC}"
        for file in "$OUTPUT_DIR"/*; do
            [ -f "$file" ] && echo "  $(basename "$file") ($(du -h "$file" | cut -f1))"
        done
        echo ""

        # Find the qcow2 image
        QCOW2_IMAGE=$(find "$OUTPUT_DIR" -name "*.qcow2" | head -n 1)
        if [ -n "$QCOW2_IMAGE" ]; then
            echo -e "${GREEN}✓ Image ready:${NC} ${YELLOW}${QCOW2_IMAGE}${NC}"
            echo ""
            echo -e "${BLUE}Next steps:${NC}"
            echo -e "  1. ${YELLOW}Apply Ansible provisioning:${NC}"
            echo -e "     ${BLUE}uv run poe provision${NC}"
            echo ""
            echo -e "  2. ${YELLOW}Test the image:${NC}"
            echo -e "     ${BLUE}uv run poe test qemu${NC}"
            echo ""
            echo -e "  3. ${YELLOW}Boot the image directly:${NC}"
            echo -e "     ${BLUE}qemu-system-${ARCH} -m 2048 -smp 2 -drive file=${QCOW2_IMAGE},format=qcow2${NC}"
        fi
    else
        echo -e "${RED}✗ Output directory not found${NC}"
        exit 1
    fi
}

#======================================
# Main execution
#======================================
main() {
    validate_prerequisites
    detect_platform
    setup_lima
    build_image
    display_results
}

# Run main function
main

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Build process completed successfully!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
