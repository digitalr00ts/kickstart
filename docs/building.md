# Building Fedora Images

This document provides detailed instructions for building Fedora images with Packer.

## Prerequisites

Ensure the following tools are installed:

- **Packer** (>= 1.15.0): `packer version`
- **QEMU** (>= 10.1.0): `qemu-system-x86_64 --version`
- **Ansible** (>= 2.20.0): `ansible --version`
- **VirtualBox** (optional): `VBoxManage --version`
- **just**: `just --version`

Check all prerequisites:

```bash
just init  # This will verify Packer and initialize plugins
```

### Host-aware QEMU accelerator defaults

Build scripts automatically select a sensible accelerator for the host OS:

- Linux: `kvm`
- macOS: `hvf`
- Fallback for unsupported hosts: `tcg`

Override at runtime when needed:

```bash
QEMU_ACCELERATOR=tcg just build-server-qemu
```

### Host-aware guest architecture defaults

Build scripts also select a default guest architecture from the host CPU:

- x86_64 host: `x86_64` guest
- arm64/aarch64 host: `aarch64` guest

Override at runtime when needed:

```bash
GUEST_ARCH=x86_64 just build-server-qemu
```

## Quick Start

1. **Review the active Fedora vars file** in `packer/fedora-44.auto.pkrvars.hcl`:

   ```bash
   # Fedora 44.1.7 URLs and checksums are already included.
   # Refresh this file if Fedora publishes a newer point release.
   vim packer/fedora-44.auto.pkrvars.hcl
   ```

2. **Initialize Packer plugins**:

   ```bash
   just init
   ```

3. **Validate configuration**:

   ```bash
   just validate
   ```

4. **Build a server image**:

   ```bash
   just build-server-qemu
   ```

## Building Images

### Using just (Recommended)

The just recipes provide convenient targets for all build operations:

```bash
# Build specific variants
just build-server-qemu          # Server for QEMU
just build-workstation-qemu     # Workstation for QEMU
just build-server-virtualbox    # Server for VirtualBox
just build-workstation-virtualbox  # Workstation for VirtualBox

# Build all variants
just build-all

# Clean and rebuild
just clean
just build-server-qemu
```

### Using Packer Directly

For more control, use Packer commands directly:

```bash
# Build server variant for QEMU
packer build \
  -only=qemu.fedora \
   -var-file=packer/fedora-44.auto.pkrvars.hcl \
   -var guest_arch=x86_64 \
   -var qemu_binary=qemu-system-x86_64 \
   -var qemu_accelerator=kvm \
  -var variant=server \
  packer/

# Build workstation variant for QEMU
packer build \
  -only=qemu.fedora \
   -var-file=packer/fedora-44.auto.pkrvars.hcl \
   -var guest_arch=aarch64 \
   -var qemu_binary=qemu-system-aarch64 \
   -var qemu_accelerator=hvf \
  -var variant=workstation \
  packer/

# Build for VirtualBox
packer build \
  -only=virtualbox-iso.fedora \
   -var-file=packer/fedora-44.auto.pkrvars.hcl \
  -var variant=server \
  packer/
```

### Build Options

#### Override Variables

```bash
# Use different disk size
packer build -var disk_size=80000 ...

# Use more memory
packer build -var memory=4096 ...

# Different Fedora version (if vars file exists)
packer build -var-file=packer/fedora-44.auto.pkrvars.hcl ...
```

#### Debug Mode

```bash
# Enable debug output
PACKER_LOG=1 packer build ...

# Interactive debugging
packer build -debug ...
```

## Ansible Collection Integration

The build process supports both local development and production workflows for Ansible collections.

### Production Build (GitHub Collection)

Default behavior - uses collection from GitHub:

```bash
just build-server-qemu
```

This will:

1. Install `drts01.collection` from GitHub
2. Apply provisioning from the collection
3. Create the final image

### Development Build (Local Collection)

For local collection development:

```bash
# Set the local collection path
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/collections

# Build with local collection
just build-server-qemu
```

The build will use your local collection instead of downloading from GitHub.

### Testing Collection Changes

1. **Modify local collection** at your development path
2. **Set environment variable**:

   ```bash
   export ANSIBLE_COLLECTIONS_PATH=/path/to/local/collections
   ```

3. **Build and test**:

   ```bash
   just build-server-qemu
   ./tests/test-qemu.sh server
   ```

### Collection Requirements

Edit `ansible/requirements.yml` to:

- Change collection version/branch
- Add additional collections
- Configure for air-gapped environments

## Build Process

Understanding what happens during a build:

### 1. ISO Download (First Build Only)

Packer downloads and caches the Fedora ISO:

- Cache location: `.packer_cache/`
- Verifies checksum before use
- Reuses cached ISO for subsequent builds

### 2. VM Creation

- Creates virtual machine with specified resources
- Attaches ISO as boot media
- Starts HTTP server for kickstart file

### 3. Kickstart Installation

- Boots from ISO
- Fetches kickstart from Packer's HTTP server
- Performs automated installation
- Reboots into installed system

### 4. Provisioning

- **Shell Provisioner**: Installs Python and dependencies
- **Ansible Provisioner**:
  - Installs collections (if needed)
  - Runs playbook for variant
  - Applies configuration
- **Shell Provisioner**: Final cleanup

### 5. Image Export

- Shuts down VM
- Exports image in platform format:
  - QEMU: qcow2 format
  - VirtualBox: OVF/OVA format
- Saves to `output/` directory

## Build Time Estimates

Typical build times (varies by hardware):

| Variant     | Platform   | Time      |
|-------------|------------|-----------|
| Server      | QEMU       | 15-25 min |
| Workstation | QEMU       | 25-40 min |
| Server      | VirtualBox | 20-30 min |
| Workstation | VirtualBox | 30-45 min |

Factors affecting build time:

- Internet connection speed (ISO download, package downloads)
- CPU cores available
- Disk I/O speed
- Amount of RAM
- Ansible provisioning complexity

## Output Files

After successful build:

```text
output/
├── qemu/
│   ├── server/
│   │   └── fedora-44       # QEMU image (qcow2)
│   └── workstation/
│       └── fedora-44
└── virtualbox/
    ├── server/
   │   └── fedora-44.ovf   # VirtualBox VM
    └── workstation/
      └── fedora-44.ovf
```

## Troubleshooting Builds

### ISO Checksum Errors

**Problem**: `invalid checksum` error

**Solution**: Verify `packer/fedora-44.auto.pkrvars.hcl` matches the current Fedora release metadata,
then update it if Fedora publishes a newer point release.

### SSH Timeout

**Problem**: Packer times out waiting for SSH

**Solutions**:

- Check kickstart has correct root password
- Verify network configuration in kickstart
- Increase `ssh_timeout` in `packer/sources.pkr.hcl`
- Check VM has booted successfully (view console if possible)

### Ansible Collection Not Found

**Problem**: Ansible cannot find `drts01.collection`

**Solutions**:

- Verify `ansible/requirements.yml` has correct GitHub URL
- Check network connectivity
- For local development, ensure `ANSIBLE_COLLECTIONS_PATH` is set correctly
- Verify collection structure matches expected format

### Out of Disk Space

**Problem**: Build fails due to insufficient disk space

**Solutions**:

- Clean previous builds: `just clean`
- Remove Packer cache: `rm -rf .packer_cache/`
- Free up host disk space
- Reduce image disk size with `-var disk_size=20000`

### VirtualBox Not Found

**Problem**: VirtualBox builds fail

**Solution**: Either install VirtualBox or use QEMU builds only

## Advanced Topics

### Custom Kickstart Modifications

To modify kickstart behavior:

1. Edit files in `http/` directory
2. No need to rebuild - Packer serves current files
3. Run validation if available: `ksvalidator http/ks-server.cfg`

### Multi-Version Builds

To support multiple Fedora versions:

1. Create new vars file: `packer/fedora-44.auto.pkrvars.hcl`
2. Update ISO URLs and checksums
3. Build with: `packer build -var-file=packer/fedora-44.auto.pkrvars.hcl ...`

### Headless vs. GUI Builds

By default, builds run headless. To watch the installation:

Edit `packer/sources.pkr.hcl` and change:

```hcl
headless = false  # Shows VM window during build
```

### Parallel Builds

Build multiple variants simultaneously:

```bash
just build-server-qemu &
just build-workstation-qemu &
wait
```

**Note**: Ensure sufficient system resources (RAM, CPU).

## Next Steps

After building images:

1. **Test**: See [testing.md](testing.md) for validation procedures
2. **Deploy**: Use images for your infrastructure
3. **Automate**: Integrate into CI/CD pipelines
4. **Customize**: Modify Ansible playbooks for your requirements

## References

- [Packer Documentation](https://www.packer.io/docs)
- [QEMU Documentation](https://www.qemu.org/documentation/)
- [VirtualBox Manual](https://www.virtualbox.org/manual/)
- [Fedora Downloads](https://getfedora.org/)
