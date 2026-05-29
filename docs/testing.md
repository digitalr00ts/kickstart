# Testing Guide

This project provides two primary test paths.

## 1) Image Validation Scenario

Run the Molecule scenario:

```bash
uv run poe test qemu
```

What it does:

- creates a test instance
- converges the Ansible configuration
- runs verification playbooks
- destroys the instance

## 2) Collection and Playbook Validation

Run collection checks:

```bash
uv run poe test ansible-collection
```

What it validates:

- core tool availability (`ansible`, `ansible-galaxy`, `python3`)
- required files in `ansible/`
- YAML parse validity for the playbook
- collection install behavior using a temporary path

## Manual Runtime Smoke Test

After building an image:

```bash
qemu-system-x86_64 \
  -m 2048 \
  -smp 2 \
  -drive file=output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2,format=qcow2 \
  -netdev user,id=net0,hostfwd=tcp::2222-:22 \
  -device virtio-net-pci,netdev=net0 \
  -nographic
```

Then verify SSH reachability and expected package state.

## Recommended CI Smoke Sequence

```bash
uv run poe build-kiwi
uv run poe test ansible-collection
uv run poe test qemu
```
