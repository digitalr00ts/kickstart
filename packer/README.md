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
└── versions/              # Future version-specific configs
```

## Configuration Files

### variables.pkr.hcl

Declares all input variables used across the templates:

- **ISO variables**: `iso_url_server`, `iso_checksum_server`, `iso_url_workstation`, `iso_checksum_workstation`
- **Build parameters**: `variant`, `fedora_version`, `disk_size`, `memory`, `cpus`
- **SSH settings**: `ssh_username`, `ssh_password`, `ssh_timeout`
- **Other settings**: `output_directory`, `http_directory`, `boot_wait`

### sources.pkr.hcl

Defines builder sources for different virtualization platforms:

- **QEMU/KVM Builder**: Primary builder with KVM acceleration
- **VirtualBox Builder**: Alternative builder (when added)
- **Plugin Requirements**: Specifies required Packer plugins and versions

**Key Features:**

- Automatic ISO selection based on `variant` variable
- Uses ternary expressions: `var.variant == "server" ? var.iso_url_server : var.iso_url_workstation`
- Server builds automatically use Server ISO
- Workstation builds automatically use Workstation ISO

### build.pkr.hcl

Defines the build process including provisioners:

1. **Ansible Provisioner**: Applies configuration using drts01 collection
2. Supports both local development (ANSIBLE_COLLECTIONS_PATH) and GitHub collections
3. Passes Fedora version to Ansible playbooks

### fedora-43.pkrvars.hcl

Version-specific variable values for Fedora 43:

- ISO URLs for Server and Workstation variants
- SHA256 checksums for verification
- Fedora version number

## Building Images

### Using Make (Recommended)

```bash
# Build server variant
make build-server-qemu

# Build workstation variant
make build-workstation-qemu
```

### Using Packer Directly

```bash
# Build server for QEMU
packer build \
  -only=qemu.fedora \
  -var-file=packer/fedora-43.pkrvars.hcl \
  -var variant=server \
  packer/

# Build workstation for QEMU
packer build \
  -only=qemu.fedora \
  -var-file=packer/fedora-43.pkrvars.hcl \
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
iso_url      = var.variant == "server" ? var.iso_url_server : var.iso_url_workstation
iso_checksum = var.variant == "server" ? var.iso_checksum_server : var.iso_checksum_workstation
```

## Adding New Fedora Versions

To support a new Fedora version (e.g., Fedora 44):

1. Create `packer/fedora-44.pkrvars.hcl`
2. Update ISO URLs and checksums
3. Set `fedora_version = "44"`
4. Build with `-var-file=packer/fedora-44.pkrvars.hcl`

Example:

```hcl
# fedora-44.pkrvars.hcl
iso_url_server = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/..."
iso_checksum_server = "sha256:..."
iso_url_workstation = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/..."
iso_checksum_workstation = "sha256:..."
fedora_version = "44"
```

## Updating ISO Checksums

Before building, verify and update ISO checksums:

```bash
# Download checksum file
wget https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-43-1.1-x86_64-CHECKSUM

# Verify checksum
sha256sum Fedora-Server-netinst-x86_64-43-1.1.iso

# Update packer/fedora-43.pkrvars.hcl with actual checksum
```

## Validation

Validate the configuration before building:

```bash
# Validate all templates
packer validate -var-file=packer/fedora-43.pkrvars.hcl packer/

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
├── qemu-{variant}/
│   └── fedora-{version}-{variant}      # QEMU qcow2 images
└── vagrant/
    └── fedora-{version}-{variant}-libvirt.box  # Vagrant boxes
```

Example:

- `output/qemu-server/fedora-43-server` (QEMU qcow2 image)
- `output/qemu-workstation/fedora-43-workstation` (QEMU qcow2 image)
- `output/vagrant/fedora-43-server-libvirt.box` (Vagrant box)
- `output/vagrant/fedora-43-workstation-libvirt.box` (Vagrant box)

## Using Vagrant Boxes

After building, you can use the Vagrant boxes directly:

### Add Box to Vagrant

```bash
# Add the box with a custom name
vagrant box add fedora-43-server output/vagrant/fedora-43-server-libvirt.box

# Verify it was added
vagrant box list
```

### Create a Vagrantfile

```ruby
# Vagrantfile
Vagrant.configure("2") do |config|
  config.vm.box = "fedora-43-server"

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
vagrant box remove fedora-43-server
```

### Quick Start with Vagrant

```bash
# One-command setup
mkdir my-project && cd my-project
vagrant box add fedora-43-server ../output/vagrant/fedora-43-server-libvirt.box
vagrant init fedora-43-server
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
