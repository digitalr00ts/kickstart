# Troubleshooting

Common issues and fixes for Kiwi NG image workflows.

## Build Fails with Missing Tools

Symptom:

- command not found for `kiwi-ng`, `qemu-system-*`, or `ansible-playbook`

Fix:

- install missing tools first
- re-run `uv run poe build-kiwi`

## macOS Build Cannot Start Virtualized Builder

Symptom:

- Lima instance does not start
- image creation exits early

Fix:

```bash
limactl list
limactl stop kiwi-builder || true
limactl start kiwi-builder
```

If needed, recreate the instance:

```bash
limactl delete kiwi-builder
uv run poe build-kiwi
```

## Provisioning Fails to Connect Over SSH

Symptom:

- timeout while waiting for SSH port

Fix:

- confirm no process is already using the forwarded port
- set a different port and retry:

```bash
SSH_PORT=2223 uv run poe provision-image output/kiwi-x86_64/fedora-minimal.x86_64-44.1.7.qcow2
```

## Wrong Architecture Binary

Symptom:

- runtime errors from QEMU binary mismatch

Fix:

- run with explicit architecture argument:

```bash
uv run poe build-kiwi 44 aarch64
uv run poe build-kiwi 44 x86_64
```

## Molecule Validation Fails

Symptom:

- scenario exits during create or verify phases

Fix:

- ensure nested virtualization support on host
- re-run with clean state:

```bash
uv run poe clean
uv run poe test qemu
```
