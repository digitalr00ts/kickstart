.PHONY: help init validate clean build-server-qemu build-server-virtualbox build-workstation-qemu build-workstation-virtualbox build-all test-qemu test-virtualbox test-all

# Default target
help: ## Show this help message
	@echo "Fedora Image Builder - Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Environment variables:"
	@echo "  FEDORA_VERSION           Fedora version to build (default: 44)"
	@echo "  ANSIBLE_COLLECTIONS_PATH Path to local Ansible collections for development"
	@echo ""

# Variables
FEDORA_VERSION ?= 44
PACKER_DIR = packer
VAR_FILE = $(PACKER_DIR)/fedora-$(FEDORA_VERSION).pkrvars.hcl
OUTPUT_DIR = output

# Tool check functions
check-packer:
	@which packer > /dev/null || (echo "Error: packer not found. Please install Packer." && exit 1)

check-qemu:
	@which qemu-system-x86_64 > /dev/null || (echo "Error: qemu-system-x86_64 not found. Please install QEMU." && exit 1)

check-virtualbox:
	@which VBoxManage > /dev/null || (echo "Error: VBoxManage not found. Please install VirtualBox." && exit 1)

check-ansible:
	@which ansible-playbook > /dev/null || (echo "Error: ansible-playbook not found. Please install Ansible." && exit 1)

# Initialization
init: check-packer ## Initialize Packer plugins
	@echo "==> Initializing Packer plugins..."
	packer init $(PACKER_DIR)/

# Validation
validate: check-packer ## Validate Packer templates
	@echo "==> Validating Packer templates..."
	packer validate -var-file=$(VAR_FILE) $(PACKER_DIR)/
	@echo "==> Validation successful!"

# Clean build artifacts
clean: ## Remove all build artifacts and output directory
	@echo "==> Cleaning build artifacts..."
	rm -rf $(OUTPUT_DIR)/
	rm -rf .packer_cache/
	rm -f *.box
	rm -f *.qcow2
	rm -f *.vdi
	@echo "==> Clean complete!"

# QEMU builds
build-server-qemu: check-packer check-qemu check-ansible ## Build Fedora Server for QEMU
	@echo "==> Building Fedora $(FEDORA_VERSION) Server for QEMU..."
	packer build \
		-only=qemu.fedora \
		-var-file=$(VAR_FILE) \
		-var variant=server \
		$(PACKER_DIR)/

build-workstation-qemu: check-packer check-qemu check-ansible ## Build Fedora Workstation for QEMU
	@echo "==> Building Fedora $(FEDORA_VERSION) Workstation for QEMU..."
	packer build \
		-only=qemu.fedora \
		-var-file=$(VAR_FILE) \
		-var variant=workstation \
		$(PACKER_DIR)/

# VirtualBox builds
build-server-virtualbox: check-packer check-virtualbox check-ansible ## Build Fedora Server for VirtualBox
	@echo "==> Building Fedora $(FEDORA_VERSION) Server for VirtualBox..."
	packer build \
		-only=virtualbox-iso.fedora \
		-var-file=$(VAR_FILE) \
		-var variant=server \
		$(PACKER_DIR)/

build-workstation-virtualbox: check-packer check-virtualbox check-ansible ## Build Fedora Workstation for VirtualBox
	@echo "==> Building Fedora $(FEDORA_VERSION) Workstation for VirtualBox..."
	packer build \
		-only=virtualbox-iso.fedora \
		-var-file=$(VAR_FILE) \
		-var variant=workstation \
		$(PACKER_DIR)/

# Build all variants
build-all: ## Build all variants (server + workstation) for all platforms
	@echo "==> Building all variants..."
	$(MAKE) build-server-qemu
	$(MAKE) build-workstation-qemu
	@if which VBoxManage > /dev/null 2>&1; then \
		$(MAKE) build-server-virtualbox; \
		$(MAKE) build-workstation-virtualbox; \
	else \
		echo "Skipping VirtualBox builds (VirtualBox not installed)"; \
	fi

# Testing targets
test-qemu: check-qemu ## Test QEMU images
	@echo "==> Testing QEMU images..."
	@if [ -x tests/test-qemu.sh ]; then \
		./tests/test-qemu.sh; \
	else \
		echo "Error: tests/test-qemu.sh not found or not executable"; \
		exit 1; \
	fi

test-virtualbox: check-virtualbox ## Test VirtualBox images
	@echo "==> Testing VirtualBox images..."
	@if [ -x tests/test-virtualbox.sh ]; then \
		./tests/test-virtualbox.sh; \
	else \
		echo "Error: tests/test-virtualbox.sh not found or not executable"; \
		exit 1; \
	fi

test-all: ## Run all tests
	@echo "==> Running all tests..."
	$(MAKE) test-qemu
	@if which VBoxManage > /dev/null 2>&1; then \
		$(MAKE) test-virtualbox; \
	else \
		echo "Skipping VirtualBox tests (VirtualBox not installed)"; \
	fi

# Quick build for development (server on QEMU)
quick: build-server-qemu ## Quick build - Fedora Server on QEMU

# Show build status
status: ## Show current build status and artifacts
	@echo "==> Build Status"
	@echo ""
	@echo "Output directory: $(OUTPUT_DIR)"
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		echo "Artifacts:"; \
		ls -lh $(OUTPUT_DIR)/; \
	else \
		echo "No build artifacts found."; \
	fi
	@echo ""
	@echo "Packer cache:"
	@if [ -d ".packer_cache" ]; then \
		du -sh .packer_cache/; \
	else \
		echo "No Packer cache."; \
	fi
