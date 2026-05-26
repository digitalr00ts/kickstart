# Packer Configuration

This directory contains the Packer HCL templates for building Fedora images.

## File Structure

```text
packer/
├── README.md              # This file
├── variables.pkr.hcl      # Variable declarations
├── sources.pkr.hcl        # Builder sources (QEMU, VirtualBox)
├── build.pkr.hcl          # Build configuration and provisioners
├── fedora-43.pkrvars.hcl  # Fedora 43 specific values
├── fedora-44.auto.pkrvars.hcl  # Fedora 44 specific values
└── versions/              # Future version-specific configs
```

## Configuration Files

### variables.pkr.hcl

Declares all input variables used across the templates:

- **ISO metadata**: `fedora_iso_metadata` map keyed by architecture and variant
- **Build parameters**: `variant`, `fedora_version`, `disk_size`, `memory`, `cpus`
- **Architecture parameters**: `guest_arch` (override), host hint detection (`host_arch`, `host_os`)
- **EFI parameters (ARM64)**: `aarch64_efi_firmware_code`, `aarch64_efi_firmware_vars`
- **SSH settings**: `ssh_username`, `ssh_password`, `ssh_timeout`
- **Other settings**: `output_directory`, `http_directory`, `boot_wait`, `headless`, `qemu_display_mode`

### sources.pkr.hcl

Defines builder sources for different virtualization platforms:

- **QEMU Builder**: Primary builder with configurable acceleration
- **VirtualBox Builder**: Alternative builder (when added)
- **Plugin Requirements**: Specifies required Packer plugins and versions

**Key Features:**

- Automatic ISO selection based on `variant` variable
- Uses architecture + variant map lookups from `fedora_iso_metadata`
- Server builds automatically use Server ISO
- Workstation builds automatically use Workstation ISO
- Host-aware accelerator selection derived from host OS (`kvm` on Linux, `hvf` on macOS, `tcg` fallback)
- Host-aware guest architecture selection via `guest_arch` (`x86_64` or `aarch64`)
- ARM64 builds use EFI boot by default to avoid BIOS boot-device-list errors on `qemu-system-aarch64`

### Variable Precedence and Defaults

The QEMU source applies a consistent precedence model for host/arch-dependent values:

1. `guest_arch` override when set
2. Host-derived defaults from `host_arch` and `host_os`

Defaults resolved from host hint:

- `linux`: accelerator `kvm`, EFI paths under `/usr/share/AAVMF/`
- `macos`: accelerator `hvf`, EFI paths under `/opt/homebrew/share/qemu/`
- `auto`: accelerator `tcg`, EFI paths under `/usr/share/AAVMF/`

`qemu_binary` is derived as `qemu-system-${guest_arch}`.
EFI firmware paths can still be overridden via `aarch64_efi_firmware_code` and `aarch64_efi_firmware_vars`.

Display backend selection when `headless=false` is controlled by `qemu_display_mode`:

- `spice` (default): SPICE GUI frontend via `-display spice-app`
- `auto`: host/arch-aware selection (`cocoa` on macOS, `gtk` on Linux x86_64, `vnc` on Linux aarch64)
- `none`, `gtk`, `cocoa`, `sdl`, `vnc`: explicit backend override

For `qemu-system-aarch64`, `gtk` may not be available depending on the host package build.

### build.pkr.hcl

Defines the build process including provisioners:

1. **Ansible Provisioner**: Applies configuration using drts01 collection
2. Supports both local development (ANSIBLE_COLLECTIONS_PATH) and GitHub collections
3. Passes Fedora version to Ansible playbooks

### fedora-44.auto.pkrvars.hcl

Version-specific variable values for Fedora 44:

- ISO URLs for Server and Workstation variants
- SHA256 checksums for verification
- Fedora version number

## Building Images

### Using Poe (Recommended)

```bash
# Build server variant
uv run poe build qemu server

# Build workstation variant
uv run poe build qemu workstation
```

### Using Packer Directly

```bash
# Build server for QEMU (x86_64)
packer build \
  -only=qemu.fedora \
  -var-file=packer/fedora-44.auto.pkrvars.hcl \
  -var guest_arch=x86_64 \
  -var variant=server \
  packer/

# Build workstation for QEMU (aarch64)
packer build \
  -only=qemu.fedora \
  -var-file=packer/fedora-44.auto.pkrvars.hcl \
  -var guest_arch=aarch64 \
  -var variant=workstation \
  packer/
```

## Automatic ISO Selection

The configuration automatically selects the correct ISO based on the `variant` variable:

| Variant     | ISO Used         | Use Case                |
|-------------|------------------|-------------------------|
| server      | Server ISO       | Minimal server installs |
| workstation | Workstation ISO  | Desktop environments    |

This is implemented in `sources.pkr.hcl`:

```hcl
iso_url      = var.fedora_iso_metadata[local.guest_arch][var.variant].url
iso_checksum = var.fedora_iso_metadata[local.guest_arch][var.variant].checksum
```

## ARM64 EFI Boot Notes

`aarch64` builds are configured to use EFI boot so Packer does not pass BIOS-style `-boot` arguments that can fail with:

```text
qemu-system-aarch64: no function defined to set boot device list for this architecture
```

Host-aware defaults for EFI firmware are applied automatically:

- macOS: `/opt/homebrew/share/qemu/edk2-aarch64-code.fd` and `/opt/homebrew/share/qemu/edk2-arm-vars.fd`
- Linux: `/usr/share/AAVMF/AAVMF_CODE.fd` and `/usr/share/AAVMF/AAVMF_VARS.fd`

Override when needed:

```bash
packer build \
  -only=qemu.fedora \
  -var-file=packer/fedora-44.auto.pkrvars.hcl \
  -var guest_arch=aarch64 \
  -var aarch64_efi_firmware_code=/custom/path/CODE.fd \
  -var aarch64_efi_firmware_vars=/custom/path/VARS.fd \
  -var variant=server \
  packer/
```

## Adding New Fedora Versions

To support a new Fedora version (e.g., Fedora 44):

1. Create `packer/fedora-44.auto.pkrvars.hcl`
2. Update `fedora_iso_metadata` entries for each architecture and variant
3. Set `fedora_version = "44"`
4. Build with `-var-file=packer/fedora-44.auto.pkrvars.hcl`

Example:

```hcl
# fedora-44.auto.pkrvars.hcl
fedora_iso_metadata = {
  x86_64 = {
    server = { url = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/...", checksum = "sha256:..." }
    workstation = { url = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/...", checksum = "sha256:..." }
  }
}
fedora_version = "44"
```

## Updating ISO Checksums

Before building, verify and update ISO checksums:

```bash
# Fedora 44.1.7 checksums are already included in packer/fedora-44.auto.pkrvars.hcl
# Refresh the file if Fedora publishes a newer point release
vim packer/fedora-44.auto.pkrvars.hcl
```

## Validation

Validate the configuration before building:

```bash
# Validate all templates
packer validate packer/

# Format templates
packer fmt -recursive packer/
```

## Customization

### Override Variables

```bash
# Use different disk size
packer build -var disk_size=80000 ...

# Use more memory
packer build -var memory=4096 ...

# More CPUs
packer build -var cpus=4 ...

# Override guest architecture explicitly
packer build -var guest_arch=aarch64 ...

# Enable GUI with default backend (SPICE)
packer build -var headless=false ...

# Use host-aware backend selection instead of SPICE
packer build -var headless=false -var qemu_display_mode=auto ...

# Force a portable GUI fallback when GTK/Cocoa is unavailable
packer build -var headless=false -var qemu_display_mode=vnc ...
```

### Debug Mode

```bash
# Enable debug output
PACKER_LOG=1 packer build ...

# Interactive debugging
packer build -debug ...
```

## Output

Built images are saved to:

```text
output/
├── qemu-{arch}-{variant}/
│   └── fedora-{version}-{arch}-{variant}      # QEMU qcow2 images
└── vagrant/
    └── fedora-{version}-{variant}-libvirt.box  # Vagrant boxes
```

Example:

- `output/qemu-x86_64-server/fedora-44-x86_64-server` (QEMU qcow2 image)
- `output/qemu-aarch64-workstation/fedora-44-aarch64-workstation` (QEMU qcow2 image)
- `output/vagrant/fedora-44-server-libvirt.box` (Vagrant box)
- `output/vagrant/fedora-44-workstation-libvirt.box` (Vagrant box)

## Using Vagrant Boxes

After building, you can use the Vagrant boxes directly:

### Add Box to Vagrant

```bash
# Add the box with a custom name
vagrant box add fedora-44-server output/vagrant/fedora-44-server-libvirt.box

# Verify it was added
vagrant box list
```

### Create a Vagrantfile

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "fedora-44-server"

  config.vm.provider "libvirt" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # Optional: Configure networking
  config.vm.network "private_network", type: "dhcp"

  # Optional: Sync folders
  config.vm.synced_folder ".", "/vagrant", type: "nfs"
end
```

### Use the Box

```bash
# Initialize and start the VM
vagrant up

# SSH into the VM
vagrant ssh

# Stop the VM
vagrant halt

# Destroy the VM
vagrant destroy

# Remove the box when no longer needed
vagrant box remove fedora-44-server
```

### Quick Start with Vagrant

```bash
# One-command setup
mkdir my-project && cd my-project
vagrant box add fedora-44-server ../output/vagrant/fedora-44-server-libvirt.box
vagrant init fedora-44-server
vagrant up
vagrant ssh
```

### Using with Different Providers

The boxes are built for libvirt (QEMU/KVM). To use them:

```bash
# Ensure you have the libvirt plugin
vagrant plugin install vagrant-libvirt

# Start with libvirt provider (default for these boxes)
vagrant up --provider=libvirt
```

## Troubleshooting

### ISO Checksum Errors

**Problem**: `invalid checksum` error

**Solution**: Download the CHECKSUM file from getfedora.org and update the checksums in the `.pkrvars.hcl` file.

### SSH Timeout

**Problem**: Packer times out waiting for SSH

**Solutions**:

- Verify kickstart has correct root password
- Check network configuration in kickstart
- Increase `ssh_timeout` variable
- Ensure VM has network connectivity

### Plugin Installation

If Packer plugins are not found:

```bash
# Initialize plugins
packer init packer/
```

## References

- [Packer HCL Templates](https://www.packer.io/docs/templates/hcl_templates)
- [QEMU Builder](https://www.packer.io/docs/builders/qemu)
- [Ansible Provisioner](https://www.packer.io/docs/provisioners/ansible)
- [Fedora Downloads](https://getfedora.org/)
