# Troubleshooting Guide

Common issues and solutions when building Fedora images with Packer.

## Build Issues

### ISO Checksum Validation Failed

**Error:**

```bash
Error: invalid checksum: encoding/hex: invalid byte: U+0052 'R'
in sha256:REPLACE_WITH_ACTUAL_FEDORA_43_SERVER_CHECKSUM
```bash

**Cause:** The active Fedora vars file doesn't match the current release metadata.

**Solution:**

1. Visit <https://getfedora.org/> and download checksum file
2. Extract SHA256 checksum for your ISO
3. Update `packer/fedora-44.auto.pkrvars.hcl`:

   ```hcl
    fedora_iso_metadata = {
       x86_64 = {
          server = { url = "...", checksum = "sha256:abc123..." }
          workstation = { url = "...", checksum = "sha256:def456..." }
       }
    }
   ```

### Undefined Variables Warning

**Error:**

```bash
Warning: Undefined variable: fedora_iso_metadata
```bash

**Cause:** Variables used in `.pkrvars.hcl` but not declared in `variables.pkr.hcl`.

**Solution:**
Use the map-based schema expected by `packer/variables.pkr.hcl`:

```hcl
fedora_iso_metadata = {
   x86_64 = {
      server = { url = "...", checksum = "sha256:..." }
      workstation = { url = "...", checksum = "sha256:..." }
   }
}
```bash

### Packer Plugins Not Found

**Error:**

```bash
Error: Failed to load plugin: terraform-plugin-sdk/v2/plugin.Serve
```bash

**Cause:** Packer plugins not initialized.

**Solution:**

```bash
packer init packer/
# or
./scripts/task.sh init
```bash

### HTTP Server Port Already in Use

**Error:**

```bash
Error: listen tcp :8000: bind: address already in use
```bash

**Cause:** Another process using port 8000 (Packer's default HTTP server port).

**Solution:**

```bash
# Find process using port
lsof -i :8000

# Kill it or change Packer HTTP port in sources.pkr.hcl
http_port_min = 8100
http_port_max = 8200
```bash

## Kickstart Issues

### SSH Timeout Waiting for VM

**Error:**

```bash
Timeout waiting for SSH
```bash

**Causes & Solutions:**

1. **Kickstart failed to complete**
   - Check QEMU console output (set `headless = false`)
   - Review kickstart syntax errors
   - Verify network configuration in kickstart

2. **Wrong root password**
   - Ensure kickstart has: `rootpw --plaintext packer`
   - Verify Packer has matching: `ssh_password = "packer"`

3. **Network not configured**
   - Check kickstart network line: `network --bootproto=dhcp --device=link --activate --onboot=yes`
   - Verify DHCP is working in VM network

4. **Firewall blocking SSH**
   - Kickstart should have: `firewall --enabled --service=ssh`

### Installation Hangs at Package Selection

**Cause:** Network issues downloading packages from mirrors.

**Solution:**

```bash
# In kickstart, specify faster mirror
url --url=https://mirrors.fedoraproject.org/metalink?repo=fedora-44&arch=x86_64

# Or use local mirror
url --url=http://your-local-mirror/fedora/44/
```bash

### Disk Partitioning Errors

**Error:**

```bash
Error: Not enough space in volume group
```bash

**Cause:** Disk size too small for selected packages.

**Solution:**

```bash
# Increase disk size in build
packer build -var disk_size=80000 ...

# Or reduce packages in kickstart
```bash

## Ansible Issues

### Ansible Collection Not Found

**Error:**

```bash
ERROR! couldn't resolve module/action 'drts01.collection.role_name'
```bash

**Causes & Solutions:**

1. **Collection not installed**

   ```bash
   # Verify collection installation
   ansible-galaxy collection list | grep drts01

   # Manually install
   ansible-galaxy collection install -r ansible/requirements.yml
   ```

1. **Wrong ANSIBLE_COLLECTIONS_PATH**

   ```bash
   # Check path
   echo $ANSIBLE_COLLECTIONS_PATH

   # Set correct path
   export ANSIBLE_COLLECTIONS_PATH=/correct/path
   ```

2. **GitHub access issues**

   ```bash
   # Test GitHub connectivity
   curl -I https://github.com/drts01/ansible-collection

   # Use SSH if HTTPS blocked
   # Edit ansible/requirements.yml to use git@github.com:...
   ```

### Python Not Found Error

**Error:**

```bash
ERROR! Ansible requires Python but it was not found on the system
```bash

**Cause:** Python not installed before Ansible provisioner runs.

**Solution:** Ensure shell provisioner installs Python first:

```hcl
provisioner "shell" {
  inline = [
    "dnf install -y python3",
    "alternatives --set python /usr/bin/python3"
  ]
}
```bash

### Playbook Syntax Error

**Error:**

```bash
ERROR! Syntax Error while loading YAML
```bash

**Cause:** Invalid YAML in playbook files.

**Solution:**

```bash
# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('ansible/playbook-server.yml'))"

# Or use ansible-lint if available
ansible-lint ansible/playbook-server.yml
```bash

## QEMU Issues

### KVM Not Available

**Error:**

```bash
Could not access KVM kernel module: No such file or directory
```bash

**Cause:** KVM not loaded or not available.

**Solution:**

```bash
# Check if KVM is available
lsmod | grep kvm

# Load KVM module (Intel)
sudo modprobe kvm_intel

# Load KVM module (AMD)
sudo modprobe kvm_amd

# Or build with software acceleration (slower) by forcing the generic host hint path
packer build \
   -only=qemu.fedora \
   -var-file=packer/fedora-44.auto.pkrvars.hcl \
   -var host_uname_s=Unknown \
   -var variant=server \
   packer/
```bash

### HVF Not Available on macOS

**Error:**

```bash
failed to initialize HVF
```bash

**Cause:** HVF is unavailable or blocked on the host.

**Solution:**

```bash
# Fall back to software acceleration by forcing the generic host hint path
packer build \
   -only=qemu.fedora \
   -var-file=packer/fedora-44.auto.pkrvars.hcl \
   -var host_uname_s=Unknown \
   -var variant=server \
   packer/

# Verify QEMU is installed
which qemu-system-x86_64
```bash

### Permission Denied on /dev/kvm

**Error:**

```bash
Could not access /dev/kvm: Permission denied
```bash

**Cause:** User not in kvm group.

**Solution:**

```bash
# Add user to kvm group
sudo usermod -a -G kvm $USER

# Re-login or newgrp
newgrp kvm

# Verify
groups | grep kvm
```bash

### QEMU Command Not Found

**Error:**

```bash
exec: "qemu-system-x86_64": executable file not found in $PATH
```bash

**Cause:** QEMU not installed.

**Solution:**

```bash
# Fedora/RHEL
sudo dnf install qemu-kvm qemu-img

# Ubuntu/Debian
sudo apt install qemu-kvm qemu-utils

# Verify
which qemu-system-x86_64
```bash

## VirtualBox Issues

### VBoxManage Not Found

**Error:**

```bash
exec: "VBoxManage": executable file not found in $PATH
```bash

**Cause:** VirtualBox not installed or not in PATH.

**Solution:**

```bash
# Install VirtualBox
# Follow https://www.virtualbox.org/wiki/Linux_Downloads

# Add to PATH if needed
export PATH=$PATH:/usr/local/bin

# Or skip VirtualBox builds
./scripts/task.sh build qemu server  # Use QEMU only
```bash

### VirtualBox Kernel Modules Not Loaded

**Error:**

```bash
Kernel driver not installed (rc=-1908)
```bash

**Cause:** VirtualBox kernel modules not compiled/loaded.

**Solution:**

```bash
# Reinstall kernel modules
sudo /sbin/vboxconfig

# Or
sudo dnf reinstall kernel-devel kernel-headers
sudo /usr/lib/virtualbox/vboxdrv.sh setup
```bash

### VirtualBox Extension Pack Missing

**Warning:** USB not available, guest additions issues.

**Solution:**

```bash
# Download and install Extension Pack
# Version must match VirtualBox version
wget https://download.virtualbox.org/virtualbox/7.0.14/Oracle_VM_VirtualBox_Extension_Pack-7.0.14.vbox-extpack

VBoxManage extpackinstall Oracle_VM_VirtualBox_Extension_Pack-7.0.14.vbox-extpack
```bash

## Build Performance Issues

### Very Slow Build

**Causes & Solutions:**

1. **Slow mirror**
   - Use faster Fedora mirror in kickstart
   - Use local mirror if available

2. **No KVM acceleration**
   - Enable KVM (see KVM issues above)
   - Verify: `grep -E 'vmx|svm' /proc/cpuinfo`

3. **Low resources**
   - Increase build resources:

     ```bash
     packer build -var memory=4096 -var cpus=4 ...
     ```

4. **Slow disk I/O**
   - Use SSD for builds
   - Check disk usage: `iostat -x 1`

### Out of Disk Space

**Error:**

```bash
No space left on device
```bash

**Solutions:**

```bash
# Clean old builds
./scripts/task.sh clean

# Remove Packer cache
rm -rf .packer_cache/

# Check disk usage
df -h
du -sh output/ .packer_cache/

# Build with smaller disk
packer build -var disk_size=20000 ...
```bash

### Out of Memory

**Error:**

```bash
Cannot allocate memory
```bash

**Solutions:**

```bash
# Reduce VM memory
packer build -var memory=1024 ...

# Close other applications
# Check available memory
free -h

# Use swap
sudo swapon -a
```bash

## Testing Issues

### Test VM Won't Start

**Cause:** Image corrupted or wrong format.

**Solution:**

```bash
# Verify image integrity
qemu-img check output/server/fedora-44

# Rebuild image
./scripts/task.sh clean
./scripts/task.sh build qemu server
```bash

### SSH Port Conflict in Tests

**Error:**

```bash
Address already in use
```bash

**Solution:**

```bash
# Use different port
SSH_PORT=3333 ./tests/test-qemu.sh server

# Or find and kill process
lsof -ti :2222 | xargs kill -9
```bash

### Test Timeout

**Cause:** VM taking too long to boot.

**Solution:**
Edit test script and increase timeout:

```bash
wait_for_ssh "localhost" "${SSH_PORT}" "${SSH_USER}" 120  # 120 attempts
```bash

## Network Issues

### No Internet in VM

**Causes & Solutions:**

1. **DNS not configured**

   ```bash
   # In kickstart, explicitly set DNS
   network --device=link --bootproto=dhcp --nameserver=8.8.8.8
   ```

1. **Firewall blocking**

   ```bash
   # Check firewall rules in VM
   ssh -p 2222 root@localhost "firewall-cmd --list-all"
   ```

2. **Network mode wrong**
   - QEMU: Using `-net user` (should work)
   - VirtualBox: Check NAT is enabled

### Cannot Download Packages

**Error:**

```bash
Failed to download metadata for repo 'fedora'
```bash

**Causes:**

- Network connectivity issue
- Mirror is down
- Firewall blocking HTTP/HTTPS

**Solution:**

```bash
# Test network from VM
ssh -p 2222 root@localhost "curl -I https://mirrors.fedoraproject.org"

# Try different mirror in kickstart
# Use metalink for automatic mirror selection
```bash

## Getting Help

If you can't resolve an issue:

1. **Enable Debug Logging:**

   ```bash
   PACKER_LOG=1 packer build ... 2>&1 | tee build.log
   ```

1. **Check Logs:**
   - Packer output
   - VM console (set `headless = false`)
   - System logs in VM: `/var/log/anaconda/`

2. **Search Issues:**
   - Packer GitHub issues
   - Fedora mailing lists
   - Stack Overflow

3. **Ask for Help:**
   - Provide full error message
   - Include Packer version: `packer version`
   - Include system info: `uname -a`
   - Attach relevant logs

4. **Report Bugs:**
   - For this project: Use GitHub issues
   - For Packer: <https://github.com/hashicorp/packer/issues>
   - For Fedora: <https://bugzilla.redhat.com/>
