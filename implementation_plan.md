# Implementation Plan

## [Overview]
Create a Packer-based infrastructure to build Fedora 43 workstation and server images for QEMU and VirtualBox with minimal kickstart configurations and Ansible provisioning.

This implementation establishes a flexible, version-aware build system for Fedora images that can be extended to support multiple Fedora versions in the future. The project uses HashiCorp Packer as the orchestration tool, minimal kickstart files for base OS installation, and the drts01 Ansible collection for post-installation configuration. The system will support two virtualization platforms (QEMU and VirtualBox), two image variants (workstation and server), and optionally produce Vagrant boxes for development use.

The structure follows a layered approach:
- Kickstart files handle OS installation with minimal configuration (network, authentication, base packages)
- Packer templates orchestrate the build process across different platforms and variants
- Ansible provisioners apply post-installation configuration using the drts01 collection
- Test scripts validate the built images before distribution
- Optional Vagrant post-processors create consumable development boxes

This design supports the principle of separation of concerns: kickstart for installation, Ansible for configuration, Packer for orchestration, and platform-specific builders for virtualization abstraction.

## [Types]
Define configuration structures and build variants for the Packer templates.

**Build Variants:**
- `fedora-workstation`: Desktop-focused image with GUI capabilities
- `fedora-server`: Minimal server image without GUI

**Platform Targets:**
- `qemu`: QEMU/KVM virtualization (libvirt compatible)
- `virtualbox`: VirtualBox virtualization

**Version Structure:**
```hcl
variable "fedora_version" {
  type    = string
  default = "43"
  description = "Fedora release version"
}

variable "iso_url" {
  type = string
  description = "URL to Fedora installation ISO"
}

variable "iso_checksum" {
  type = string
  description = "SHA256 checksum of the ISO file"
}

variable "variant" {
  type    = string
  default = "server"
  description = "Image variant: server or workstation"
  validation {
    condition     = contains(["server", "workstation"], var.variant)
    error_message = "Variant must be either 'server' or 'workstation'."
  }
}

variable "output_directory" {
  type    = string
  default = "output"
  description = "Directory for build artifacts"
}

variable "disk_size" {
  type    = string
  default = "40960"
  description = "Disk size in MB"
}

variable "memory" {
  type    = string
  default = "2048"
  description = "Memory allocation in MB"
}

variable "cpus" {
  type    = string
  default = "2"
  description = "Number of CPU cores"
}
```

**Source Block Structure:**
```hcl
source "qemu" "fedora" {
  # Common settings
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = "${var.output_directory}/qemu-${var.variant}"
  
  # Hardware
  disk_size        = var.disk_size
  memory           = var.memory
  cpus             = var.cpus
  
  # Network and access
  http_directory   = "http"
  ssh_username     = "root"
  ssh_password     = "packer"
  ssh_timeout      = "30m"
  
  # Boot configuration
  boot_wait        = "5s"
  boot_command     = ["<up><tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-${var.variant}.cfg<enter>"]
  
  # Accelerator
  accelerator      = "kvm"
  format           = "qcow2"
}

source "virtualbox-iso" "fedora" {
  # Similar structure adapted for VirtualBox
  iso_url          = var.iso_url
  iso_checksum     = var.iso_checksum
  output_directory = "${var.output_directory}/virtualbox-${var.variant}"
  
  # Hardware
  disk_size        = var.disk_size
  memory           = var.memory
  cpus             = var.cpus
  
  # VirtualBox specific
  guest_os_type    = "Fedora_64"
  hard_drive_interface = "sata"
  iso_interface    = "sata"
  
  # Network and access
  http_directory   = "http"
  ssh_username     = "root"
  ssh_password     = "packer"
  ssh_timeout      = "30m"
  
  # Boot configuration
  boot_wait        = "5s"
  boot_command     = ["<up><tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-${var.variant}.cfg<enter>"]
}
```

## [Files]
Comprehensive file structure for the project with all necessary configurations and scripts.

**New Files to Create:**

1. **Project Root:**
   - `README.md` - Project documentation with usage instructions
   - `.gitignore` - Exclude build artifacts, .packer_cache, output/, *.box, *.qcow2, *.vdi, etc.
   - `Makefile` - Build automation targets for common operations

2. **Kickstart Directory (http/):**
   - `http/ks-base.cfg` - Base kickstart template with common settings
   - `http/ks-server.cfg` - Server variant kickstart (includes ks-base.cfg)
   - `http/ks-workstation.cfg` - Workstation variant kickstart (includes ks-base.cfg)

3. **Packer Templates (packer/):**
   - `packer/variables.pkr.hcl` - Variable definitions
   - `packer/sources.pkr.hcl` - Source block definitions for QEMU and VirtualBox
   - `packer/build.pkr.hcl` - Build block with provisioners and post-processors
   - `packer/fedora-43.pkrvars.hcl` - Fedora 43 specific variable values (ISO URLs, checksums)

4. **Ansible Configuration (ansible/):**
   - `ansible/requirements.yml` - Ansible Galaxy requirements for drts01 collection
   - `ansible/playbook-server.yml` - Server provisioning playbook
   - `ansible/playbook-workstation.yml` - Workstation provisioning playbook
   - `ansible/ansible.cfg` - Ansible configuration for Packer runs

5. **Test Scripts (tests/):**
   - `tests/test-qemu.sh` - QEMU image validation script
   - `tests/test-virtualbox.sh` - VirtualBox image validation script
   - `tests/validation.sh` - Common validation functions and checks

6. **Scripts Directory (scripts/):**
   - `scripts/cleanup.sh` - Pre-build cleanup script
   - `scripts/prepare-output.sh` - Prepare output directory structure
   - `scripts/vagrant-prepare.sh` - Prepare image for Vagrant packaging

7. **Documentation (docs/):**
   - `docs/kickstart-reference.md` - Kickstart configuration documentation
   - `docs/building.md` - Build process documentation
   - `docs/testing.md` - Testing and validation documentation
   - `docs/troubleshooting.md` - Common issues and solutions

**Directory Structure:**
```
kickstart/
├── README.md
├── .gitignore
├── Makefile
├── http/
│   ├── ks-base.cfg
│   ├── ks-server.cfg
│   └── ks-workstation.cfg
├── packer/
│   ├── variables.pkr.hcl
│   ├── sources.pkr.hcl
│   ├── build.pkr.hcl
│   ├── fedora-43.pkrvars.hcl
│   └── versions/
│       └── (future version files)
├── ansible/
│   ├── requirements.yml
│   ├── ansible.cfg
│   ├── playbook-server.yml
│   └── playbook-workstation.yml
├── scripts/
│   ├── cleanup.sh
│   ├── prepare-output.sh
│   └── vagrant-prepare.sh
├── tests/
│   ├── test-qemu.sh
│   ├── test-virtualbox.sh
│   └── validation.sh
├── docs/
│   ├── kickstart-reference.md
│   ├── building.md
│   ├── testing.md
│   └── troubleshooting.md
└── output/
    ├── qemu-server/
    ├── qemu-workstation/
    ├── virtualbox-server/
    └── virtualbox-workstation/
```

## [Functions]
Key functions and scripts used throughout the build and validation process.

**Makefile Targets:**
- `make build-server-qemu` - Build server image for QEMU
- `make build-server-virtualbox` - Build server image for VirtualBox
- `make build-workstation-qemu` - Build workstation image for QEMU
- `make build-workstation-virtualbox` - Build workstation image for VirtualBox
- `make build-all` - Build all variants and platforms
- `make test-qemu` - Test QEMU images
- `make test-virtualbox` - Test VirtualBox images
- `make test-all` - Run all tests
- `make clean` - Remove build artifacts
- `make validate` - Validate Packer templates

**Bash Functions in tests/validation.sh:**
```bash
# Check if VM boots successfully
check_boot() {
  local vm_name=$1
  local platform=$2
  # Implementation
}

# Verify SSH connectivity
check_ssh() {
  local ip_address=$1
  local ssh_key=$2
  # Implementation
}

# Validate installed packages
check_packages() {
  local vm_name=$1
  local expected_packages=("${@:2}")
  # Implementation
}

# Check disk partitioning
check_partitions() {
  local vm_name=$1
  # Implementation
}

# Verify Ansible provisioning results
check_ansible_state() {
  local vm_name=$1
  # Implementation
}
```

**Bash Functions in scripts/cleanup.sh:**
```bash
# Remove old build artifacts
cleanup_output() {
  local output_dir=$1
  # Implementation
}

# Clear Packer cache
cleanup_cache() {
  # Implementation
}

# Remove temporary files
cleanup_temp() {
  # Implementation
}
```

**Packer Provisioner Blocks (in packer/build.pkr.hcl):**
```hcl
provisioner "shell" {
  inline = [
    "dnf install -y python3 python3-pip",
    "alternatives --set python /usr/bin/python3"
  ]
}

provisioner "ansible" {
  playbook_file = "ansible/playbook-${var.variant}.yml"
  galaxy_file   = "ansible/requirements.yml"
  extra_arguments = [
    "--extra-vars",
    "fedora_version=${var.fedora_version}"
  ]
}

provisioner "shell" {
  script = "scripts/cleanup.sh"
}
```

## [Classes]
No classes are needed for this implementation as the project primarily uses declarative configuration files (HCL, YAML) and shell scripts rather than object-oriented programming.

## [Dependencies]
External tools, packages, and collections required for the build system.

**System Dependencies:**
- Packer >= 1.15.0 (installed)
- QEMU >= 10.0 (installed - version 10.1.4)
- VirtualBox >= 7.0 (needs installation)
- Ansible >= 2.15 (needs installation)
- Python3 >= 3.9 (likely installed, verify)
- Make (for Makefile automation)
- curl or wget (for ISO downloads)
- jq (for JSON processing in scripts)

**Packer Plugins (auto-installed via packer init):**
```hcl
packer {
  required_version = ">= 1.15.0"
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}
```

**Ansible Collections (ansible/requirements.yml):**

Option 1 - Install from GitHub during build:
```yaml
---
collections:
  - name: https://github.com/drts01/ansible-collection.git
    type: git
    version: trunk
```

Option 2 - Use local collection (preferred for development):
```yaml
# Leave empty or minimal, use ANSIBLE_COLLECTIONS_PATH instead
---
collections: []
```

For local collections, configure in `ansible/ansible.cfg`:
```ini
[defaults]
collections_path = /path/to/local/collections:~/.ansible/collections:/usr/share/ansible/collections
```

Or set environment variable in Packer provisioner:
```hcl
provisioner "ansible" {
  playbook_file = "ansible/playbook-${var.variant}.yml"
  extra_arguments = [
    "--extra-vars",
    "fedora_version=${var.fedora_version}",
    "-e",
    "ansible_collections_path=/path/to/local/collections"
  ]
  ansible_env_vars = [
    "ANSIBLE_COLLECTIONS_PATH=/path/to/local/collections:~/.ansible/collections"
  ]
}
```

**Python Dependencies (for Ansible):**
- ansible-core
- jinja2
- pyyaml

**ISO Requirements:**
- Fedora 43 Server netinst ISO
- Fedora 43 Workstation netinst ISO
- URLs and SHA256 checksums to be defined in fedora-43.pkrvars.hcl

## [Testing]
Comprehensive testing strategy to validate built images.

**Test File: tests/validation.sh**
Common validation functions that can be sourced by platform-specific tests:
- VM boot validation
- SSH connectivity checks
- Package installation verification
- Disk partitioning validation
- Service status checks
- Network configuration validation
- User account verification
- SELinux status checks

**Test File: tests/test-qemu.sh**
QEMU-specific test sequence:
1. Start VM using qemu-system-x86_64 with built qcow2 image
2. Wait for boot completion
3. Verify SSH access
4. Run validation functions
5. Check QEMU guest agent if installed
6. Verify disk format and virtual hardware
7. Shutdown VM gracefully
8. Generate test report

**Testing Ansible Collection Changes:**

Development workflow for testing collection changes:

1. **Local Collection Testing (Fast Iteration):**
   ```bash
   # Build with local collection
   export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection
   packer build -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/
   ```

2. **Standalone Ansible Testing (No Packer):**
   ```bash
   # Test playbook against existing VM without rebuilding
   cd ansible/
   ansible-playbook -i <vm-ip>, playbook-server.yml \
     --extra-vars "ansible_collections_path=/path/to/local/collections" \
     --user root
   ```

3. **Incremental Testing Workflow:**
   - Build base image once with minimal Ansible (or skip Ansible)
   - Boot the VM manually (QEMU or VirtualBox)
   - Run ansible-playbook directly against the running VM
   - Iterate on collection changes and re-run playbook
   - Once satisfied, rebuild full image to validate end-to-end

4. **Ansible Check Mode (Dry Run):**
   ```bash
   # Test what would change without making changes
   ansible-playbook --check playbook-server.yml
   ```

5. **Production Testing (GitHub Collection):**
   ```bash
   # Build with GitHub collection to validate production configuration
   unset ANSIBLE_COLLECTIONS_PATH
   packer build -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/
   ```

**Test Script: tests/test-ansible-collection.sh**
New script to test collection changes without full Packer build:
- Spin up existing image in VM
- Apply playbook with local collection
- Verify expected state changes
- Compare results between local and GitHub versions
- Report differences

**Test File: tests/test-virtualbox.sh**
VirtualBox-specific test sequence:
1. Import OVF/OVA into VirtualBox
2. Start VM using VBoxManage
3. Wait for boot completion
4. Verify SSH access
5. Run validation functions
6. Check VirtualBox Guest Additions if installed
7. Verify virtual hardware configuration
8. Shutdown VM gracefully
9. Generate test report

**Manual Testing Checklist:**
- Boot time verification (< 2 minutes for server, < 3 minutes for workstation)
- Memory usage baseline (server < 512MB idle, workstation varies)
- Network connectivity (DHCP, static IP, DNS resolution)
- Package management (dnf install/update functionality)
- Ansible idempotency (re-run provisioning playbook)
- User creation and authentication
- SSH key authentication
- Firewall rules (if configured)
- SELinux enforcement mode

**Automated Test Execution:**
```makefile
test-all: test-qemu test-virtualbox

test-qemu:
	@echo "Testing QEMU images..."
	@bash tests/test-qemu.sh output/qemu-server
	@bash tests/test-qemu.sh output/qemu-workstation

test-virtualbox:
	@echo "Testing VirtualBox images..."
	@bash tests/test-virtualbox.sh output/virtualbox-server
	@bash tests/test-virtualbox.sh output/virtualbox-workstation
```

## [Implementation Order]
Step-by-step sequence to build the system incrementally with validation at each stage.

1. **Project Structure and Documentation**
   - Create directory structure (http/, packer/, ansible/, scripts/, tests/, docs/)
   - Write README.md with project overview and quick start
   - Create .gitignore for build artifacts
   - Initialize git repository structure if needed

2. **Kickstart File Development**
   - Create http/ks-base.cfg with minimal configuration (language, keyboard, timezone, network, auth, bootloader, partitioning)
   - Create http/ks-server.cfg including base + server-specific packages
   - Create http/ks-workstation.cfg including base + workstation-specific packages
   - Test kickstart syntax with ksvalidator if available

3. **Packer Template Foundation**
   - Create packer/variables.pkr.hcl with all variable definitions
   - Create packer/sources.pkr.hcl with QEMU source block
   - Create packer/fedora-43.pkrvars.hcl with Fedora 43 ISO URLs and checksums
   - Create minimal packer/build.pkr.hcl with shell provisioner only
   - Run `packer init packer/` to install plugins
   - Run `packer validate packer/` to verify template syntax

4. **QEMU Builder Implementation**
   - Complete QEMU source configuration in sources.pkr.hcl
   - Test build of server variant: `packer build -only=qemu.fedora -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/`
   - Manually test resulting qcow2 image boots and is accessible via SSH
   - Document any issues and adjust kickstart/packer configuration

5. **Ansible Integration**
   - Create ansible/requirements.yml with drts01 collection
   - Create ansible/ansible.cfg with appropriate settings for Packer
   - Create ansible/playbook-server.yml with basic host configuration
   - Add ansible provisioner to packer/build.pkr.hcl
   - Test build with Ansible provisioning
   - Verify Ansible collection installation and playbook execution

6. **VirtualBox Builder Implementation**
   - Add VirtualBox source block to sources.pkr.hcl
   - Update build.pkr.hcl to include virtualbox-iso.fedora source
   - Test build of server variant: `packer build -only=virtualbox-iso.fedora -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/`
   - Manually test resulting VirtualBox image
   - Compare configuration with QEMU variant for consistency

7. **Workstation Variant Implementation**
   - Verify http/ks-workstation.cfg includes GUI packages
   - Create ansible/playbook-workstation.yml with desktop-specific configuration
   - Test workstation build for QEMU
   - Test workstation build for VirtualBox
   - Verify GUI functionality if applicable

8. **Build Automation**
   - Create Makefile with targets for each build variant
   - Add clean, validate, and init targets
   - Create scripts/cleanup.sh for pre-build cleanup
   - Create scripts/prepare-output.sh for directory structure
   - Test all Makefile targets

9. **Testing Infrastructure**
   - Create tests/validation.sh with common test functions
   - Create tests/test-qemu.sh with QEMU-specific tests
   - Create tests/test-virtualbox.sh with VirtualBox-specific tests
   - Run tests against existing builds
   - Document test results and fix any failures

10. **Vagrant Post-Processor (Optional)**
    - Add vagrant post-processor to build.pkr.hcl
    - Create scripts/vagrant-prepare.sh for Vagrant-specific setup
    - Configure for both libvirt (QEMU) and virtualbox providers
    - Test vagrant box creation
    - Test vagrant box import and boot: `vagrant box add` and `vagrant up`

11. **Documentation and Polish**
    - Write docs/building.md with detailed build instructions
    - Write docs/kickstart-reference.md documenting kickstart choices
    - Write docs/testing.md with testing procedures
    - Write docs/troubleshooting.md with common issues
    - Update README.md with complete usage examples
    - Add CI/CD considerations if applicable

12. **Final Validation**
    - Run `make build-all` to build all variants
    - Run `make test-all` to validate all builds
    - Verify disk space usage is reasonable
    - Verify build time is acceptable
    - Test on clean system if possible
    - Create release notes for Fedora 43 images
