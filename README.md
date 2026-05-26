# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Automated build system for creating reproducible Fedora workstation and server images for QEMU and
VirtualBox using Packer, Kickstart, and Ansible.

## Overview

This project provides a Packer-based infrastructure to build Fedora images with:

- **Minimal kickstart configurations** for base OS installation
- **Ansible provisioning** using the drts01 collection
- **Multi-platform support** for QEMU builds on Linux and macOS
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
- uv (for running Poe tasks)

### Task Runner

- Primary: `uv run poe <task> [args]`
- Compatibility: `./scripts/task.sh <command> [args]` delegates to Poe by default
- Legacy bash path: `KICKSTART_TASK_LEGACY=1 ./scripts/task.sh <command> [args]`

### Initial Setup

```sh
# Clone the repository
git clone https://github.com/digitalr00ts/kickstart.git
cd kickstart

# Fedora 44.1.7 ISO metadata is included in packer/fedora-44.auto.pkrvars.hcl.
# Refresh that file if Fedora publishes a newer point release.

# Initialize Packer plugins
uv run poe init

# Validate templates
uv run poe validate
```text

### Build Your First Image

```bash
# Build Fedora 44 server image for QEMU
uv run poe build qemu server

# Optional: override guest architecture (x86_64, aarch64)
GUEST_ARCH=aarch64 uv run poe build qemu server

# Or build for VirtualBox
uv run poe build virtualbox server

# Build workstation variant
uv run poe build qemu workstation
```text

Images are output to the `output/` directory organized by platform and variant.

### Build All Variants

```bash
# Build all combinations (server/workstation × QEMU/VirtualBox)
uv run poe build all
```text

### Testing Images

```bash
# Test QEMU images
uv run poe test qemu server

# Test VirtualBox images
uv run poe test virtualbox server

# Test all platforms
uv run poe test all server
```text

## Project Structure

```text
kickstart/
├── http/                    # Kickstart files served via HTTP during install
│   ├── ks-base.cfg         # Base configuration (shared)
│   ├── ks-server.cfg       # Server variant kickstart
│   └── ks-workstation.cfg  # Workstation variant kickstart
├── packer/                  # Packer HCL templates
│   ├── variables.pkr.hcl   # Variable definitions
│   ├── sources.pkr.hcl     # Builder sources (QEMU, VirtualBox)
│   ├── build.pkr.hcl       # Build configuration and provisioners
│   ├── fedora-43.pkrvars.hcl  # Fedora 43 specific values
│   └── fedora-44.auto.pkrvars.hcl  # Fedora 44 specific values
├── ansible/                 # Ansible provisioning
│   ├── requirements.yml    # Collection requirements
│   ├── ansible.cfg         # Ansible configuration
│   ├── playbook-server.yml # Server provisioning playbook
│   └── playbook-workstation.yml  # Workstation provisioning playbook
├── scripts/                 # Utility scripts
├── molecule/                # Molecule scenarios and shared verify tasks
└── docs/                    # Documentation
```text

## Ansible Collection Support

### Using Local Collection (Development)

```bash
# Set environment variable to use local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection
uv run poe build qemu server
```text

### Using GitHub Collection (Production)

```bash
# Unset local path to use GitHub collection
unset ANSIBLE_COLLECTIONS_PATH
uv run poe build qemu server
```text

### Testing Collection Changes

Test Ansible changes without full rebuild:

```bash
# Boot an existing image manually, then:
cd ansible/
ansible-playbook -i <vm-ip>, playbook-server.yml \
  --extra-vars "ansible_collections_path=/path/to/local/collections" \
  --user root
```text

## Available Task Commands

```bash
uv run poe --help                              # Show usage
uv run poe init                                # Initialize Packer plugins
uv run poe validate                            # Validate Packer templates
uv run poe build qemu server                   # Build server for QEMU
uv run poe build virtualbox server             # Build server for VirtualBox
uv run poe build qemu workstation              # Build workstation for QEMU
uv run poe build virtualbox workstation        # Build workstation for VirtualBox
uv run poe build all                           # Build all variants and platforms
uv run poe test qemu server                    # Test QEMU images
uv run poe test virtualbox server              # Test VirtualBox images
uv run poe test all server                     # Test all images
uv run poe clean                               # Remove build artifacts
uv run poe status                              # Show build status and artifacts
uv run poe build qemu server                   # Quick build - server on QEMU only
```text

Run `uv run poe --help` to see command usage.

## System Requirements

### Host System

- Linux host (Fedora, RHEL, Ubuntu, Debian) or macOS host
- CPU with virtualization support (Intel VT-x or AMD-V)
- QEMU accelerator support:
  - Linux default: `kvm`
  - macOS default: `hvf`
  - Fallback: `tcg` (portable, slower)

### Disk Space

- ~5GB per image variant (sparse qcow2 format for QEMU)
- ~10GB for ISO cache (.packer_cache/)
- ~50GB recommended for building all variants with headroom

### Memory

- Server builds: 2GB VM + 2GB host = 4GB+ total recommended
- Workstation builds: 2GB VM + 2GB host = 4GB+ total recommended  
- More memory speeds up builds significantly

### Build Time

- Server variant: 15-25 minutes (QEMU with hardware acceleration)
- Workstation variant: 25-40 minutes (QEMU with hardware acceleration)
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
- ✅ Build automation (scripts/task.sh dispatcher with shared helpers)
- ✅ Testing infrastructure (Molecule scenarios and verify tasks)
- ✅ Complete documentation

### Ready for Use

- ✅ QEMU builds with host-aware acceleration (kvm on Linux, hvf on macOS)
- ⚠️ VirtualBox builds (templates ready, requires VirtualBox installation)
- ✅ Fedora 44.1.7 ISO URLs and checksums are included in `packer/fedora-44.auto.pkrvars.hcl`

### Optional (Not Yet Implemented)

- ⬜ Vagrant post-processor (templates prepared)
- ⬜ Additional Fedora versions (structure supports, needs vars files)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.

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
```text

See [docs/development.md](docs/development.md) for full development guide.
