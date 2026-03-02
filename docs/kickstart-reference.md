# Kickstart Configuration Reference

This document describes the kickstart configuration files used for Fedora image builds.

## Overview

The kickstart files follow a minimal configuration philosophy, providing only essential settings while allowing maximum flexibility for post-installation customization via Ansible.

## File Structure

```
http/
├── ks-base.cfg         # Base configuration (shared)
├── ks-server.cfg       # Server variant (includes base)
└── ks-workstation.cfg  # Workstation variant (includes base)
```

## Base Configuration (ks-base.cfg)

The base kickstart provides fundamental system settings:

### Installation Method
- **Text mode**: Non-interactive installation
- **ISO install**: Installs from mounted ISO media

### Localization
- **Language**: en_US.UTF-8
- **Keyboard**: us
- **Timezone**: UTC (modify for your location)

### Network Configuration
- **Method**: DHCP with IPv4
- **Hostname**: localhost.localdomain (temporary, change post-installation)
- **Interface**: Automatic activation on boot

### Authentication
- **Root Password**: "packer" (TEMPORARY - for build automation only)
  - ⚠️ **Security Warning**: This is a temporary password used only during the build process
  - Must be changed post-installation or via Ansible provisioning
  - Never use these images in production without changing the password

### Disk Partitioning
- **Strategy**: Automatic partitioning with LVM
- **VG Name**: fedora
- **Layout**:
  - Boot partition (ext4)
  - Root LV (/)
  - Swap LV
- **Benefits**: Easy resizing, snapshots, and management

### Bootloader
- **Location**: MBR
- **Timeout**: 1 second (fast boot)

### Services
- **Firewall**: Enabled
- **SELinux**: Enforcing (default security posture)

### Base Packages
- **Minimal**: @core group
- **Python 3**: Required for Ansible provisioning
- **Additional**: Network tools, development basics

## Server Variant (ks-server.cfg)

Includes base configuration plus server-specific packages:

### Additional Packages
- **System Administration**: sudo, vim, tmux
- **Network Tools**: curl, wget, bind-utils, net-tools, nmap-ncat
- **Version Control**: git
- **Monitoring**: htop
- **Compression**: bzip2, tar

### Use Cases
- Headless servers
- Virtual machines
- Container hosts
- Development environments

## Workstation Variant (ks-workstation.cfg)

Includes base configuration plus desktop environment:

### Desktop Environment
- **Environment**: GNOME Workstation (@workstation-product-environment)
- **X Server**: @base-x
- **Display Manager**: GDM (GNOME Display Manager)

### Additional Applications
- **Browser**: Firefox
- **Terminal**: gnome-terminal
- **Development**: @development-tools
- **Utilities**: Standard GNOME applications

### Use Cases
- Developer workstations
- Desktop VMs
- Testing environments
- GUI-based administration

## Post-Installation

After kickstart completes:

1. System reboots automatically
2. Packer connects via SSH (root/packer)
3. Ansible provisioning applies additional configuration
4. Final cleanup removes temporary artifacts

## Customization

To customize kickstart files:

### Modify Base Settings
Edit `http/ks-base.cfg` for changes affecting all variants:
- Timezone: Change `timezone UTC` line
- Root password: Change `rootpw` line (don't forget to update Packer variables)
- Partition scheme: Modify `autopart` or replace with custom `part` directives

### Modify Packages
Edit variant-specific files:
- **Server**: Add packages to `%packages` section in `ks-server.cfg`
- **Workstation**: Add packages to `%packages` section in `ks-workstation.cfg`

### Add Post-Install Scripts
Add `%post` sections to kickstart files for shell commands that run after package installation but before reboot.

Example:
```bash
%post
echo "Custom configuration" > /etc/custom.conf
systemctl enable myservice
%end
```

## Validation

Validate kickstart syntax (if ksvalidator is available):
```bash
ksvalidator http/ks-base.cfg
ksvalidator http/ks-server.cfg
ksvalidator http/ks-workstation.cfg
```

## References

- [Fedora Kickstart Documentation](https://docs.fedoraproject.org/en-US/fedora/latest/install-guide/appendixes/Kickstart_Syntax_Reference/)
- [Anaconda Kickstart Options](https://pykickstart.readthedocs.io/)
- [Red Hat Kickstart Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/performing_an_advanced_rhel_installation/kickstart_references)

## Security Considerations

1. **Root Password**: Always change the temporary root password via Ansible or post-installation
2. **SELinux**: Keep enabled in enforcing mode for production systems
3. **Firewall**: Configure appropriate rules via Ansible for your use case
4. **Updates**: Run `dnf update` after installation to get latest security patches
5. **SSH Keys**: Replace password authentication with SSH keys in production
