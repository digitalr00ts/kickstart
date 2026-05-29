# Kiwi NG Proof-of-Concept

This directory contains a minimal proof-of-concept migration from Kickstart/Packer to Kiwi NG for building Fedora images.

## Overview

**Status**: ⚠️ Proof-of-Concept - Testing Phase

This PoC demonstrates:

- Building Fedora images directly with Kiwi NG (no VM installation)
- Lima integration for macOS compatibility
- Native Linux support
- Equivalent functionality to the existing kickstart.cfg

## Architecture

```text
┌────────────────────────────────────────────┐
│  Host (macOS/Linux)                        │
│                                            │
│  ┌────────────────────────────────────     │
│  │  Lima VM (macOS) / Native (Linux)  │    │
│  │                                    │    │
│  │  ┌───────────────────────────┐     │    │
│  │  │  Kiwi NG                  │     │    │
│  │  │  - Reads XML description  │     │    │
│  │  │  - Installs packages      │     │    │
│  │  │  - Runs config.sh         │     │    │
│  │  │  - Outputs qcow2 image    │     │    │
│  │  └───────────────────────────┘     │    │
│  └────────────────────────────────────┘    │
└────────────────────────────────────────────┘
```

## Files

- `fedora-44-minimal.kiwi` - Kiwi XML image description (converted from kickstart.cfg)
- `config.sh` - Configuration script (equivalent to kickstart %post section)
- `README.md` - This file

## Prerequisites

### macOS

```bash
# Install Lima
brew install lima

# The build script will automatically:
# - Create a Lima VM named 'kiwi-builder'
# - Install Kiwi NG in the VM
# - Configure the environment
```

### Linux (Fedora)

```bash
# Install Kiwi NG
sudo dnf install -y kiwi-cli python3-kiwi kiwi-systemdeps

# Ensure you have sudo access
```

## Usage

### Quick Start

```bash
# Build Fedora 44 for current architecture
./scripts/build-with-kiwi.sh

# Build specific version
./scripts/build-with-kiwi.sh 44

# Build for specific architecture
./scripts/build-with-kiwi.sh 44 x86_64
./scripts/build-with-kiwi.sh 44 aarch64
```

### What the Script Does

1. **Validates** prerequisites (Kiwi description files exist)
2. **Detects** platform (macOS or Linux)
3. **Sets up** Lima VM on macOS (if needed):
   - Creates VM with **writable home directory mount** (required for Kiwi)
   - Configures 4 CPUs, 8GB RAM, 50GB disk
   - Provisions Kiwi NG automatically
4. **Installs** Kiwi NG (if not present)
5. **Builds** the image using Kiwi NG
6. **Outputs** qcow2 image to `output/kiwi-{arch}/`

### First Run on macOS

The first run will:

- Create a Lima VM (2-5 minutes)
- Install Kiwi NG in the VM (2-5 minutes)
- Build the image (10-20 minutes)

Subsequent runs will be faster as the VM is already set up.

### Output

Images are created in:

```text
output/kiwi-x86_64/
├── fedora-minimal.x86_64-44.1.7.qcow2    # Main image
└── fedora-minimal.x86_64-44.1.7.packages  # Package list
```

## Testing the Image

### Boot with QEMU

```bash
# Simple boot test
qemu-system-x86_64 \
    -m 2048 \
    -smp 2 \
    -drive file=output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2,format=qcow2 \
    -netdev user,id=net0 \
    -device virtio-net-pci,netdev=net0

# Login with:
# - User: vagrant
# - Password: vagrant
```

### Apply Ansible Provisioning

Once the base image is built, you can apply Ansible provisioning:

```bash
# (This step will be automated in the full implementation)
# For now, manually boot the image and run ansible-playbook
```

## Comparison: Kickstart vs Kiwi

| Aspect | Kickstart (Current) | Kiwi NG (PoC) |
| -------- | -------------------- | --------------: |
| Build Time | 15-40 minutes | 10-20 minutes |
| Approach | VM installation | Direct image creation |
| Configuration | .cfg file | XML + shell script |
| macOS Support | Via Packer + QEMU | Via Lima |
| Output | qcow2 via Packer | Native qcow2 |

## Converted Features

✅ Features successfully converted from kickstart.cfg:

- [x] Base package selection (@core, openssh, python3, etc.)
- [x] Package exclusions (plymouth, initial-setup-gui, etc.)
- [x] User creation (admin, vagrant)
- [x] Sudo configuration for vagrant user
- [x] Root password locking
- [x] DNF optimization settings
- [x] Machine-specific data cleanup
- [x] Service enablement (sshd, NetworkManager)
- [x] Firewall configuration
- [x] SELinux enforcing
- [x] Btrfs filesystem
- [x] EFI boot
- [x] Timezone and locale settings

## Known Limitations (PoC)

⚠️ This is a proof-of-concept. Not yet implemented:

- [ ] Ansible integration (post-processing step)
- [ ] Poe task integration
- [ ] Molecule testing updates
- [ ] ARM64/aarch64 variant (needs separate .kiwi file)
- [ ] Vagrant box generation
- [ ] Full documentation
- [ ] CI/CD integration

## Next Steps

After validating this PoC:

1. **Test the built image** thoroughly
2. **Compare** performance with Packer/Kickstart approach
3. **Integrate** Ansible provisioning as post-processor
4. **Create** ARM64 variant description
5. **Update** Molecule scenarios
6. **Migrate** full project structure

## Troubleshooting

### Lima Issues on macOS

The build script automatically configures Lima with **writable mounts** (required for Kiwi to create output directories).

```bash
# Check Lima status
limactl list

# View Lima configuration
limactl show-ssh kiwi-builder

# Restart Lima VM
limactl stop kiwi-builder
limactl start kiwi-builder

# Access Lima shell
limactl shell kiwi-builder

# Delete and recreate (if configuration needs updating)
limactl delete kiwi-builder
./scripts/build-with-kiwi.sh
```

**Important**: If you created the Lima VM before the writable mounts fix, delete and recreate it:

```bash
limactl stop kiwi-builder
limactl delete kiwi-builder
./scripts/build-with-kiwi.sh
```

### Build Failures

```bash
# Check Kiwi NG logs
# On macOS (Lima):
limactl shell kiwi-builder sudo journalctl -xe

# On Linux:
sudo journalctl -xe

# Validate Kiwi description
kiwi-ng system describe --description kiwi/
```

### Permission Issues

Kiwi NG requires root privileges to build images. The build script uses `sudo`.

## Resources

- [Kiwi NG Documentation](https://osinside.github.io/kiwi/)
- [Kiwi NG GitHub](https://github.com/OSInside/kiwi)
- [Lima Documentation](https://lima-vm.io/)
- [Original kickstart.cfg](../http/kickstart.cfg)

## Feedback

This is a proof-of-concept. Please test and provide feedback on:

- Build success/failure
- Build time comparison
- Image quality
- macOS Lima experience
- Any issues encountered
