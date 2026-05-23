# Testing Built Images

This document describes how to test and validate Fedora images built with Packer.

## Overview

The testing infrastructure validates that built images:

- Boot successfully
- Have network connectivity
- Include required packages
- Can be accessed via SSH
- Have proper disk partitioning
- Run expected services

## Quick Testing

### Test QEMU Images

```bash
# Test server image
make test-qemu VARIANT=server

# Test workstation image
make test-qemu VARIANT=workstation

# Or use the test script directly
./tests/test-qemu.sh server
./tests/test-qemu.sh workstation
```bash

### Test VirtualBox Images

```bash
# Test server image
make test-virtualbox VARIANT=server

# Test workstation image
make test-virtualbox VARIANT=workstation

# Or use the test script directly
./tests/test-virtualbox.sh server
./tests/test-virtualbox.sh workstation
```bash

### Test All Platforms

```bash
make test-all
```bash

## Test Scripts

### validation.sh

Common validation functions used by all test scripts:

**Functions:**

- `wait_for_ssh()` - Wait for SSH to become available
- `check_boot()` - Verify system booted successfully
- `check_ssh()` - Test SSH connectivity
- `check_packages()` - Verify required packages installed
- `check_partitions()` - Check disk partitioning
- `check_lvm()` - Verify LVM configuration
- `check_python()` - Ensure Python is available
- `check_services()` - Check systemd services
- `check_network()` - Test network connectivity
- `check_dnf()` - Verify package manager works
- `get_system_info()` - Display system information

### test-qemu.sh

Tests QEMU-built images by:

1. Launching VM with QEMU
2. Forwarding SSH port (default: 2222)
3. Waiting for SSH availability
4. Running validation checks
5. Cleaning up VM on exit

**Usage:**

```bash
./tests/test-qemu.sh [variant]

# Examples
./tests/test-qemu.sh server
./tests/test-qemu.sh workstation

# With custom SSH port
SSH_PORT=3333 ./tests/test-qemu.sh server
```bash

### test-virtualbox.sh

Tests VirtualBox-built images by:

1. Importing OVF into VirtualBox
2. Configuring port forwarding (default: 2223)
3. Starting VM headless
4. Running validation checks
5. Removing test VM on exit

**Usage:**

```bash
./tests/test-virtualbox.sh [variant]

# Examples
./tests/test-virtualbox.sh server
./tests/test-virtualbox.sh workstation
```bash

### test-ansible-collection.sh

Tests Ansible collection integration:

- Verifies Ansible installation
- Validates configuration files
- Checks playbook syntax
- Tests collection installation
- Validates both local and GitHub workflows

**Usage:**

```bash
./tests/test-ansible-collection.sh

# With local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/collections
./tests/test-ansible-collection.sh
```bash

## Manual Testing

### Boot QEMU Image Manually

```bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -drive file=output/server/fedora-44,format=qcow2 \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::2222-:22 \
  -display gtk
```bash

Access via SSH:

```bash
ssh -p 2222 root@localhost
# Password: packer
```bash

### Import to VirtualBox Manually

```bash
# Import OVF
VBoxManage import output/server/fedora-44.ovf

# Start VM
VBoxManage startvm fedora-44

# Or use GUI
virtualbox &
```bash

### Test with libvirt

```bash
# Import to libvirt
virt-install \
  --name fedora-44-test \
  --memory 2048 \
  --vcpus 2 \
  --disk path=output/server/fedora-44,format=qcow2 \
  --import \
  --network default \
  --graphics vnc

# Access console
virt-viewer fedora-44-test
```bash

## Ansible Collection Testing Workflow

### Test Production Workflow (GitHub)

```bash
# 1. Build image (installs from GitHub)
make build-server-qemu

# 2. Test the build
./tests/test-qemu.sh server

# 3. Verify Ansible provisioning worked
ssh -p 2222 root@localhost "rpm -qa | grep -i <expected-package>"
```bash

### Test Development Workflow (Local)

```bash
# 1. Set local collection path
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection

# 2. Verify collection structure
./tests/test-ansible-collection.sh

# 3. Build with local collection
make build-server-qemu

# 4. Test the build
./tests/test-qemu.sh server

# 5. Verify your local changes were applied
ssh -p 2222 root@localhost "check your changes here"
```bash

### Test Collection Changes Iteratively

```bash
# 1. Make changes to local collection
vim /path/to/local/ansible-collection/roles/myrol/tasks/main.yml

# 2. Quick rebuild (assumes ISO already cached)
make clean
make build-server-qemu

# 3. Test changes
./tests/test-qemu.sh server
```bash

## Validation Checks

### Standard Server Checks

- System boots successfully
- SSH access works
- Python 3 installed
- DNF package manager functional
- Required packages: sudo, curl, wget, git, vim
- Services running: sshd, chronyd
- Network connectivity
- LVM configured
- Root partition mounted

### Standard Workstation Checks

All server checks plus:

- Firefox installed
- GNOME packages present
- GDM service available
- Desktop environment packages

## Test Results

### Successful Test Output

```bash
========================================
Testing QEMU Image: Fedora 44 server
========================================
ℹ Image found: output/server/fedora-44
ℹ Starting QEMU VM...
✓ QEMU VM started (PID: 12345)
ℹ Waiting for SSH on localhost:2222...
✓ SSH is available
✓ System is running
✓ SSH access working
✓ Python is installed: Python 3.11.5
✓ DNF is working
✓ Root partition is mounted
✓ LVM is configured
✓ Network connectivity is working
✓ Package sudo is installed
✓ Package curl is installed
...
========================================
Test Summary
========================================
Passed: 15
Failed: 0
========================================
```bash

### Failed Test Output

```bash
✗ Package firefox is not installed
✗ SSH access failed
========================================
Test Summary
========================================
Passed: 13
Failed: 2
========================================
```bash

## Troubleshooting Tests

### SSH Connection Fails

**Problem**: Test cannot connect via SSH

**Solutions:**

- Verify VM actually booted (check QEMU process is running)
- Check SSH port is not already in use: `lsof -i :2222`
- Verify root password is still "packer" in kickstart
- Increase wait time in test script
- Try connecting manually: `ssh -p 2222 root@localhost`

### VM Won't Start

**Problem**: QEMU or VirtualBox fails to start VM

**Solutions:**

- Check image file exists and is readable
- Verify sufficient RAM available on host
- For QEMU: Check KVM is available: `lsmod | grep kvm`
- For VirtualBox: Check VBoxManage is in PATH
- Review test script output for specific errors

### Package Checks Fail

**Problem**: Required packages reported as not installed

**Solutions:**

- Verify kickstart includes the packages
- Check Ansible playbook for package installation tasks
- SSH into VM manually and verify: `rpm -qa | grep package-name`
- Review build logs for package installation errors

### Port Already in Use

**Problem**: SSH port forwarding fails

**Solutions:**

- Use different port: `SSH_PORT=3333 ./tests/test-qemu.sh server`
- Find and kill process using port: `lsof -ti :2222 | xargs kill`
- Wait for previous test cleanup to complete

## Continuous Integration

### CI Pipeline Example

```yaml
# .gitlab-ci.yml or .github/workflows/build.yml
test-images:
  script:
    - make init
    - make validate
    - make build-server-qemu
    - make test-qemu
  artifacts:
    paths:
      - output/
    expire_in: 1 week
```bash

### Automated Testing Script

```bash
#!/bin/bash
# ci-test.sh - Complete build and test cycle

set -e

echo "==> Initializing"
make init

echo "==> Validating"
make validate

echo "==> Building"
make build-server-qemu

echo "==> Testing"
make test-qemu

echo "==> All tests passed!"
```bash

## Performance Testing

### Boot Time Test

```bash
# Time from VM start to SSH available
time ./tests/test-qemu.sh server | grep "SSH is available"
```bash

### Resource Usage Test

```bash
# Monitor resource usage during test
vmstat 1 &
./tests/test-qemu.sh server
killall vmstat
```bash

### Image Size

```bash
# Check image sizes
ls -lh output/*/*
du -sh output/
```bash

## Best Practices

1. **Clean Environment**: Run `make clean` before important tests
2. **Test Both Variants**: Always test both server and workstation
3. **Test All Platforms**: If supporting multiple platforms, test all
4. **Automated Tests**: Integrate tests into CI/CD
5. **Keep Tests Updated**: Update test scripts when adding new requirements
6. **Document Failures**: Note any test failures and their resolutions

## Next Steps

- See [troubleshooting.md](troubleshooting.md) for common issues
- See [building.md](building.md) for build customization
- Integrate tests into your CI/CD pipeline
- Create custom validation functions for your specific requirements
