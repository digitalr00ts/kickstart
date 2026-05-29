# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Automated image build system for generating minimal Fedora images using **Kiwi NG** (primary) or Packer (legacy),
with Ansible provisioning.

## 🚀 Quick Start (Kiwi NG - Recommended)

```bash
# Install Lima (macOS only)
brew install lima

# Build Fedora 44 image (auto-detects macOS/Linux)
uv run poe build-kiwi

# Build with Ansible provisioning (complete workflow)
uv run poe build-full

# Output: output/kiwi-<arch>/fedora-minimal.<arch>-44.1.7.qcow2
```

**Why Kiwi NG?**

- ⚡ **Faster**: 10-20 min vs 15-40 min (no VM installation overhead)
- 🍎 **macOS Support**: Automatic Lima VM integration with writable mounts
- 🐧 **Linux Native**: Direct Kiwi execution
- 📦 **Fedora Aligned**: Official Fedora image building tool

## Overview

This project provides two methods for building Fedora images:

### 1. Kiwi NG (Primary - New!)

- Direct image assembly from packages
- Lima integration for macOS
- Faster build times
- Fedora's official approach

### 2. Packer + Kickstart (Legacy)

- VM-based installation via Anaconda
- Multi-platform support (QEMU, VirtualBox)
- Established tooling

Both methods support:

- **Ansible provisioning** using the drts01 collection
- **Multi-architecture** support (x86_64, aarch64)
- **Local collection development** workflow
- **Reproducible** builds

## Features

- 🚀 **Automated Builds**: Zero manual intervention required
- 🔄 **Reproducible**: Consistent images every time
- 🧪 **Fast Development Cycle**: Test Ansible collection changes without full rebuilds
- 🎯 **Minimal Base**: Installation handles only essential settings
- 🔧 **Flexible Configuration**: Ansible manages post-installation setup
- ✅ **Validated**: Comprehensive testing infrastructure included

## Prerequisites

### For Kiwi NG Builds (Recommended)

**macOS:**

```bash
brew install lima
```

**Linux (Fedora):**

```bash
sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps
```

### For Packer Builds (Legacy)

- Packer >= 1.15.0
- QEMU >= 10.0
- Ansible >= 2.15

### Common Requirements

- uv (for running Poe tasks)
- Ansible >= 2.15 (for provisioning)

## Kiwi NG Workflow (Primary)

### Build Image Only

```bash
# Build Fedora 44 for current architecture
uv run poe build-kiwi

# Build specific version and architecture
uv run poe build-kiwi 44 x86_64
uv run poe build-kiwi 44 aarch64
```

### Build + Ansible Provisioning

```bash
# Complete workflow: Kiwi build + Ansible provisioning
uv run poe build-full

# With specific version/architecture
uv run poe build-full 44 x86_64
```

### Apply Ansible to Existing Image

```bash
# Provision a previously built image
uv run poe provision-image output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2
```

### What Happens During Build

1. **Platform Detection**: Auto-detects macOS (uses Lima) or Linux (native Kiwi)
2. **Lima Setup** (macOS only): Creates VM with writable mounts, installs Kiwi NG
3. **Kiwi Build**: Assembles image directly from packages (no VM boot)
4. **Ansible Provisioning** (if using build-full): Boots image, applies playbook
5. **Output**: qcow2 image ready to use

### First Run (macOS)

The first Kiwi build will:

1. Create Lima VM named `kiwi-builder` (2-5 minutes)
2. Install Kiwi NG automatically (2-5 minutes)
3. Build the image (10-20 minutes)

Subsequent builds reuse the existing Lima VM.

## Packer Workflow (Legacy)

### Initial Setup

```bash
# Initialize Packer plugins
uv run poe init

# Validate templates
uv run poe validate
```

### Build Images

```bash
# Build with Packer
uv run poe build

# Optional: override guest architecture
GUEST_ARCH=aarch64 uv run poe build
```

## Project Structure

```text
kickstart/
├── kiwi/                        # Kiwi NG descriptions (primary)
│   ├── fedora-44-minimal.kiwi   # x86_64 image description
│   ├── fedora-44-aarch64.kiwi   # ARM64 image description
│   ├── config.sh                # Post-installation script
│   └── README.md                # Kiwi NG documentation
├── http/                        # Kickstart files (legacy)
│   ├── kickstart.cfg            # Minimal kickstart
│   └── scale-av.ks              # Scale Computing variant
├── packer/                      # Packer templates (legacy)
│   ├── variables.pkr.hcl
│   ├── sources.pkr.hcl
│   ├── build.pkr.hcl
│   └── fedora-44.auto.pkrvars.hcl
├── ansible/                     # Ansible provisioning
│   ├── requirements.yml         # Collection requirements
│   ├── ansible.cfg
│   └── playbook.yml            # Provisioning playbook
├── scripts/                     # Build scripts
│   ├── build-with-kiwi.sh      # Kiwi build wrapper
│   └── provision-with-ansible.sh  # Ansible post-processor
├── molecule/                    # Testing infrastructure
└── docs/                        # Documentation
```

## Ansible Collection Support

### Using Local Collection (Development)

```bash
# Set environment variable to use local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection

# Build with local collection
uv run poe build-full
```

The Ansible provisioner will automatically use your local collection for rapid development.

### Using GitHub Collection (Production)

```bash
# Unset local path to use GitHub collection
unset ANSIBLE_COLLECTIONS_PATH

# Build with GitHub collection
uv run poe build-full
```

## Available Commands

### Kiwi NG Commands (Primary)

```bash
uv run poe build-kiwi [version] [arch]    # Build base image with Kiwi NG
uv run poe provision-image <image>        # Apply Ansible to built image
uv run poe build-full [version] [arch]    # Build + Ansible (complete)
uv run poe kiwi-clean                     # Remove Kiwi build artifacts
```

### Packer Commands (Legacy)

```bash
uv run poe init                           # Initialize Packer plugins
uv run poe validate                       # Validate Packer templates
uv run poe build                          # Build with Packer
```

### Testing & Utilities

```bash
uv run poe test qemu                      # Test QEMU images
uv run poe test ansible-collection        # Validate Ansible collection
uv run poe clean                          # Remove all build artifacts
uv run poe status                         # Show build status
```

Run `uv run poe --help` to see all available commands.

## System Requirements

### Kiwi NG Builds

**macOS:**

- Apple Silicon (M1/M2/M3) or Intel
- macOS 10.10+ for Hypervisor.framework
- 4GB+ RAM (8GB recommended)
- 20GB+ free disk space

**Linux:**

- Fedora, RHEL, Ubuntu, or Debian
- 4GB+ RAM (8GB recommended)
- 20GB+ free disk space
- Sudo access for Kiwi

### Build Times

- **Kiwi NG**: 10-20 minutes (first run 20-30 min with setup)
- **Packer**: 15-40 minutes
- Times vary by network speed, CPU, and disk I/O

## Testing Images

Boot a built image with QEMU:

```bash
# x86_64
qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -drive file=output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2,format=qcow2 \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic

# ARM64
qemu-system-aarch64 \
    -M virt \
    -cpu max \
    -m 2048 \
    -smp 2 \
    -drive file=output/kiwi-aarch64/fedora-minimal.aarch64-44.1.7.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic

# Login: vagrant / vagrant
```

## Documentation

- **[Kiwi NG PoC](kiwi/README.md)** - Kiwi NG detailed documentation
- **[Migration Guide](KIWI-MIGRATION-POC.md)** - Kickstart → Kiwi NG migration details
- **[Building Images](docs/building.md)** - Packer build instructions
- **[Kickstart Reference](docs/kickstart-reference.md)** - Kickstart configuration explained
- **[Testing Guide](docs/testing.md)** - Testing procedures
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions
- **[Development Guide](docs/development.md)** - Development workflow

## Troubleshooting

### Lima Issues (macOS)

```bash
# Check Lima status
limactl list

# Restart Lima VM
limactl stop kiwi-builder && limactl start kiwi-builder

# Delete and recreate (if needed)
limactl delete kiwi-builder
uv run poe build-kiwi
```

### Build Failures

```bash
# Validate Kiwi description
kiwi-ng system describe --description kiwi/

# Check logs (macOS)
limactl shell kiwi-builder sudo journalctl -xe

# Check logs (Linux)
sudo journalctl -xe
```

### Permission Issues

Kiwi NG requires root privileges. The build script uses `sudo` automatically.

## Security Notes

⚠️ **Important Security Considerations:**

1. **User Passwords**: Built images include:
   - `admin` user (encrypted password)
   - `vagrant` user (password: vagrant)
   - Root password is **locked** by default

2. **SSH Access**: Images are configured for password-based SSH
   - For production: disable password auth, use SSH keys
   - Configure firewall rules appropriately

3. **SELinux**: Enabled in enforcing mode by default (recommended)

4. **Updates**: Run `dnf update` after building to get latest security patches

See [kiwi/config.sh](kiwi/config.sh) for post-installation configuration details.

## Migration Status

### Completed ✅

- Kiwi NG build system (primary method)
- Lima integration for macOS
- Ansible post-processor
- ARM64 support
- Task runner integration
- Complete documentation

### Legacy (Maintained) ⚠️

- Packer + Kickstart builds still available
- Will be deprecated in future release

## Current Status

### Production Ready

- ✅ Kiwi NG builds (x86_64, aarch64)
- ✅ Lima integration for macOS
- ✅ Ansible provisioning
- ✅ Testing infrastructure

### Future Enhancements

- ⬜ Vagrant box post-processing
- ⬜ CI/CD automation
- ⬜ Cloud image variants (AWS, Azure, GCP)

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
```

See [docs/development.md](docs/development.md) for full development guide.

## Acknowledgments

- Built with [Kiwi NG](https://osinside.github.io/kiwi/)
- macOS support via [Lima](https://lima-vm.io/)
- Provisioning with [Ansible](https://www.ansible.com/)
- Testing with [Molecule](https://molecule.readthedocs.io/)
