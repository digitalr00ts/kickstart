# Building Images

This guide covers image creation with Kiwi NG and optional post-build provisioning.

## Prerequisites

- `uv`
- `kiwi-ng`
- `qemu-system-*`
- `ansible-playbook`
- `ansible-galaxy`

On macOS, install Lima:

```bash
brew install lima
```

## Quick Build

```bash
uv run poe build-kiwi
```

Build with explicit version and architecture:

```bash
uv run poe build-kiwi 44 x86_64
uv run poe build-kiwi 44 aarch64
```

## Build and Provision in One Step

```bash
uv run poe build-full
```

The command builds an image first, then applies the Ansible playbook to the first qcow2 image found under `output/kiwi-*`.

## Provision an Existing Image

```bash
uv run poe provision-image output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2
```

## Build Outputs

Artifacts are written to:

- `output/kiwi-x86_64/`
- `output/kiwi-aarch64/`

Use status helpers:

```bash
uv run poe status
uv run poe kiwi-clean
uv run poe clean
```

## Environment Overrides

Useful environment variables:

- `ANSIBLE_COLLECTIONS_PATH`: use a local collection checkout
- `ANSIBLE_PLAYBOOK`: override playbook path for provisioning
- `MOLECULE_POLICY_MODE`: influence test policy behavior
