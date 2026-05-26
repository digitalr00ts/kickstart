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
./scripts/task.sh test qemu server

# Test workstation image
./scripts/task.sh test qemu workstation

# Or run Molecule scenarios directly
molecule test -s qemu-server
molecule test -s qemu-workstation
```bash

### Test VirtualBox Images

```bash
# Test server image
./scripts/task.sh test virtualbox server

# Test workstation image
./scripts/task.sh test virtualbox workstation

# Or run Molecule scenarios directly
molecule test -s virtualbox-server
molecule test -s virtualbox-workstation
```bash

### Test All Platforms

```bash
./scripts/task.sh test all server
```bash

## Molecule Test Scenarios

Image lifecycle and validation are now managed by Molecule delegated scenarios.

### Scenario map

- `qemu-server` - boots a server qcow2 image in QEMU and verifies baseline checks
- `qemu-workstation` - boots a workstation qcow2 image in QEMU and verifies desktop checks
- `virtualbox-server` - imports server OVF into VirtualBox and verifies baseline checks
- `virtualbox-workstation` - imports workstation OVF into VirtualBox and verifies desktop checks

### Strict policy modes

Set `MOLECULE_POLICY_MODE` before running tests:

- `strict` - fail on all checks (default)
- `mixed` - enforce core checks; gate LVM/network conditionally
- `parity` - keep warning-style checks non-fatal

### task.sh test qemu

Runs the QEMU Molecule scenario by:

1. Running `molecule test -s qemu-<variant>`
2. Creating and destroying VM lifecycle in scenario `create`/`destroy`
3. Executing checks in scenario `verify`

**Usage:**

```bash
./scripts/task.sh test qemu [variant]

# Examples
./scripts/task.sh test qemu server
./scripts/task.sh test qemu workstation

# With strict checks
MOLECULE_POLICY_MODE=strict ./scripts/task.sh test qemu server

# Downgrade to mixed checks
MOLECULE_POLICY_MODE=mixed ./scripts/task.sh test qemu server

# Downgrade to parity checks
MOLECULE_POLICY_MODE=parity ./scripts/task.sh test qemu server
```bash

### task.sh test virtualbox

Runs the VirtualBox Molecule scenario by:

1. Running `molecule test -s virtualbox-<variant>`
2. Importing and starting VM in scenario `create`
3. Executing checks in scenario `verify`
4. Powering off and unregistering VM in scenario `destroy`

**Usage:**

```bash
./scripts/task.sh test virtualbox [variant]

# Examples
./scripts/task.sh test virtualbox server
./scripts/task.sh test virtualbox workstation
```bash

### task.sh test ansible-collection

Tests Ansible collection integration:

- Verifies Ansible installation
- Validates configuration files
- Checks playbook syntax
- Tests collection installation
- Validates both local and GitHub workflows

**Usage:**

```bash
./scripts/task.sh test ansible-collection

# With local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/collections
./scripts/task.sh test ansible-collection
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
./scripts/task.sh build qemu server

# 2. Test the build
./scripts/task.sh test qemu server

# 3. Verify Ansible provisioning worked
ssh -p 2222 root@localhost "rpm -qa | grep -i <expected-package>"
```bash

### Test Development Workflow (Local)

```bash
# 1. Set local collection path
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/ansible-collection

# 2. Verify collection structure
./scripts/task.sh test ansible-collection

# 3. Build with local collection
./scripts/task.sh build qemu server

# 4. Test the build
./scripts/task.sh test qemu server

# 5. Verify your local changes were applied
ssh -p 2222 root@localhost "check your changes here"
```bash

### Test Collection Changes Iteratively

```bash
# 1. Update your local collection
vim /path/to/local/ansible-collection/roles/myrol/tasks/main.yml

# 2. Quick rebuild (assumes ISO already cached)
./scripts/task.sh clean
./scripts/task.sh build qemu server

# 3. Test changes
./scripts/task.sh test qemu server
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
INFO     qemu-server scenario test matrix: dependency, create, converge, verify, destroy
INFO     Performing prerun with role_name_check=0...
INFO     Running qemu-server > create
PLAY [Prepare molecule test instance] ****************************************
...
PLAY RECAP *******************************************************************
localhost                  : ok=12   changed=4    unreachable=0    failed=0

INFO     Running qemu-server > verify
PLAY [Verify image behavior] *************************************************
TASK [Assert required packages are installed] ********************************
ok: [instance] => (item=sudo)
ok: [instance] => (item=curl)
...
PLAY RECAP *******************************************************************
instance                   : ok=24   changed=0    unreachable=0    failed=0

INFO     Running qemu-server > destroy
INFO     Scenario completed successfully
```bash

### Failed Test Output

```bash
INFO     Running qemu-workstation > verify
TASK [Assert required packages are installed] ********************************
failed: [instance] (item=firefox) =>
  msg: Required package missing: firefox

TASK [Assert external network in strict mode] ********************************
fatal: [instance]: FAILED! =>
  msg: External network probe failed in strict mode

PLAY RECAP *******************************************************************
instance                   : ok=18   changed=0    unreachable=0    failed=2

ERROR    Scenario 'qemu-workstation' failed
```bash

## Troubleshooting Tests

### SSH Connection Fails

**Problem**: Test cannot connect via SSH

**Solutions:**

- Verify VM actually booted (check QEMU process is running)
- Check SSH port is not already in use: `lsof -i :2222`
- Verify root password is still "packer" in kickstart
- Increase wait time in `molecule/shared/verify-common.yml`
- Try connecting manually: `ssh -p 2222 root@localhost`

### VM Won't Start

**Problem**: QEMU or VirtualBox fails to start VM

**Solutions:**

- Check image file exists and is readable
- Verify sufficient RAM available on host
- For QEMU: Check KVM is available: `lsmod | grep kvm`
- For VirtualBox: Check VBoxManage is in PATH
- Review Molecule output for create/verify step errors

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

- Change `VM_SSH_PORT` in scenario config, for example `molecule/qemu-server/molecule.yml`
- Find and kill process using port: `lsof -ti :2222 | xargs kill`
- Wait for previous test cleanup to complete

## Continuous Integration

### CI Pipeline Example

```yaml
# .gitlab-ci.yml or .github/workflows/build.yml
test-images:
  script:
    - ./scripts/task.sh init
    - ./scripts/task.sh validate
    - ./scripts/task.sh build qemu server
    - ./scripts/task.sh test qemu server
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
./scripts/task.sh init

echo "==> Validating"
./scripts/task.sh validate

echo "==> Building"
./scripts/task.sh build qemu server

echo "==> Testing"
./scripts/task.sh test qemu server

echo "==> All tests passed!"
```bash

## Performance Testing

### Boot Time Test

```bash
# Time from VM start to SSH available
time ./scripts/task.sh test qemu server
```bash

### Resource Usage Test

```bash
# Monitor resource usage during test
vmstat 1 &
./scripts/task.sh test qemu server
killall vmstat
```bash

### Image Size

```bash
# Check image sizes
ls -lh output/*/*
du -sh output/
```bash

## Best Practices

1. **Clean Environment**: Run `./scripts/task.sh clean` before important tests
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
