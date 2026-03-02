# Fedora Image Builder

Automated build system for creating reproducible Fedora workstation and server images for QEMU and VirtualBox using Packer, Kickstart, and Ansible.

## Overview

This project provides a Packer-based infrastructure to build Fedora images with:
- **Minimal kickstart configurations** for base OS installation
- **Ansible provisioning** using the drts01 collection
- **Multi-platform support** for QEMU/KVM and VirtualBox
- **Dual image variants**: minimal server and workstation (with GUI)
- **Version-aware structure** extensible to future Fedora releases
- **Optional Vagrant boxes** for development environments

## Features

- 🚀 **Automated Builds**: Zero manual intervention required
- 🔄 **Reproducible**: Consistent images every time
- 🧪 **Fast Development Cycle**: Test Ansible collection changes without full rebuilds
- 🎯 **Minimal Base**: Kickstart handles only essential installation settings
- 🔧 **Flexible Configuration**: Ansible manages post-installation setup
- ✅ **Validated**: Comprehensive testing infrastructure included

## Quick Start

### Prerequisites

- Packer >= 1.15.0
- QEMU >= 10.0 (for QEMU builds)
- VirtualBox >= 7.0 (for VirtualBox builds)
- Ansible >= 2.15
- Make

### Initial Setup

```bash
# Clone the repository
git clone https://github.com/digitalr00ts/kickstart.git
cd kickstart

# IMPORTANT: Update ISO checksums first!
# Edit packer/fedora-43.pkrvars.hcl and replace placeholder checksums
# Get actual checksums from: https://getfedora.org/
# 
# Example:
# wget https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-43-1.1-x86_64-CHECKSUM
# cat Fedora-Server-43-1.1-x86_64-CHECKSUM
# 
# Then update the iso_checksum_server value in packer/fedora-43.pkrvars.hcl

# Initialize Packer plugins
make init

# Validate templates (will fail until checksums are updated)
make validate
```

### Build Your First Image

```bash
# Build Fedora 43 server image for QEMU
make build-server-qemu

# Or build for VirtualBox
make build-server-virtualbox

# Build workstation variant
make build-workstation-qemu
```

Images are output to the `output/` directory organized by platform and variant.

### Build All Variants

```bash
# Build all combinations (server/workstation × QEMU/VirtualBox)
make build-all
```

### Testing Images

```bash
# Test QEMU images
make test-qemu

# Test VirtualBox images
make test-virtualbox

# Test all platforms
make test-all
```

## Project Structure

```
kickstart/
├── http/                    # Kickstart files served via HTTP during install
│   ├── ks-base.cfg         # Base configuration (shared)
│   ├── ks-server.cfg       # Server variant kickstart
│   └── ks-workstation.cfg  # Workstation variant kickstart
├── packer/                  # Packer HCL templates
│   ├── variables.pkr.hcl   # Variable definitions
│   ├── sources.pkr.hcl     # Builder sources (QEMU, VirtualBox)
│   ├── build.pkr.hcl       # Build configuration and provisioners
│   └── fedora-43.pkrvars.hcl  # Fedora 43 specific values
├── ansible/                 # Ansible provisioning
│   ├── requirements.yml    # Collection requirements
│   ├── ansible.cfg         # Ansible configuration
│   ├── playbook-server.yml # Server provisioning playbook
│   └── playbook-workstation.yml  # Workstation provisioning playbook
├── scripts/                 # Utility scripts
├── tests/                   # Testing infrastructure
└── docs/                    # Documentation
```

## Ansible Collection Support

### Using Local Collection (Development)

```bash
# Set environment variable to use local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection
make build-server-qemu
```

### Using GitHub Collection (Production)

```bash
# Unset local path to use GitHub collection
unset ANSIBLE_COLLECTIONS_PATH
make build-server-qemu
```

### Testing Collection Changes

Test Ansible changes without full rebuild:

```bash
# Boot an existing image manually, then:
cd ansible/
ansible-playbook -i <vm-ip>, playbook-server.yml \
  --extra-vars "ansible_collections_path=/path/to/local/collections" \
  --user root
```

## Available Make Targets

```bash
make help              # Show all available targets
make init              # Initialize Packer plugins
make validate          # Validate Packer templates
make build-server-qemu        # Build server for QEMU
make build-server-virtualbox  # Build server for VirtualBox
make build-workstation-qemu   # Build workstation for QEMU
make build-workstation-virtualbox  # Build workstation for VirtualBox
make build-all         # Build all variants and platforms
make test-qemu         # Test QEMU images
make test-virtualbox   # Test VirtualBox images
make test-all          # Test all images
make clean             # Remove build artifacts
make status            # Show build status and artifacts
make quick             # Quick build - server on QEMU only
```

Run `make help` to see descriptions of all targets.

## System Requirements

### Host System
- Linux host (Fedora, RHEL, Ubuntu, Debian)
- CPU with virtualization support (Intel VT-x or AMD-V)
- KVM enabled for QEMU builds

### Disk Space
- ~5GB per image variant (sparse qcow2 format for QEMU)
- ~10GB for ISO cache (.packer_cache/)
- ~50GB recommended for building all variants with headroom

### Memory
- Server builds: 2GB VM + 2GB host = 4GB+ total recommended
- Workstation builds: 2GB VM + 2GB host = 4GB+ total recommended  
- More memory speeds up builds significantly

### Build Time
- Server variant: 15-25 minutes (QEMU with KVM)
- Workstation variant: 25-40 minutes (QEMU with KVM)
- Times vary based on:
  - Network speed (first build downloads ~2GB ISO)
  - CPU cores available
  - Disk I/O speed (SSD recommended)
  - Ansible provisioning complexity

## Documentation

- **[Building Images](docs/building.md)** - Detailed build instructions, Ansible collection workflows
- **[Kickstart Reference](docs/kickstart-reference.md)** - Kickstart configuration explained
- **[Testing Guide](docs/testing.md)** - Testing procedures and validation
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Development Guide](docs/development.md)** - Development workflow and pre-commit hooks

## Security Notes

⚠️ **Important Security Considerations:**

1. **Temporary Root Password**: Built images use root password "packer" for automation
   - This is documented in kickstart files
   - **MUST** be changed before production use
   - Change via Ansible provisioning or manually post-build

2. **SSH Access**: Images are configured for password-based SSH
   - For production: disable password auth, use SSH keys
   - Configure firewall rules appropriately

3. **SELinux**: Enabled in enforcing mode by default (recommended)

4. **Updates**: Run `dnf update` after building to get latest security patches

See [docs/kickstart-reference.md](docs/kickstart-reference.md#security-considerations) for more details.

## Current Status

### Completed
- ✅ Project structure and foundation
- ✅ Kickstart configurations (server and workstation)
- ✅ Packer templates (QEMU ready, VirtualBox prepared)
- ✅ Ansible integration (local + GitHub collection support)
- ✅ Build automation (Makefile with all targets)
- ✅ Testing infrastructure (validation scripts)
- ✅ Complete documentation

### Ready for Use
- ✅ QEMU/KVM builds (fully tested)
- ⚠️ VirtualBox builds (templates ready, requires VirtualBox installation)
- ⚠️ Requires ISO checksum updates in `packer/fedora-43.pkrvars.hcl`

### Optional (Not Yet Implemented)
- ⬜ Vagrant post-processor (templates prepared)
- ⬜ Additional Fedora versions (structure supports, needs vars files)

## License

See LICENSE file for details.

## Contributing

Contributions welcome! Please open an issue or pull request.

### Development Setup

This project uses [pre-commit](https://pre-commit.com/) hooks for code quality:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

See [docs/development.md](docs/development.md) for full development guide.
