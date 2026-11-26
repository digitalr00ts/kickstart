# Testing Guide

Validate a built Fedora QCOW2 image with Molecule and native QEMU on Linux or macOS.
Install the [host dependencies](building.md#prerequisites) first. These checks validate a VM, not physical hardware.

## Image Validation Scenario

Build an image, then run the Molecule scenario:

```bash
uv run poe build
uv run poe test
```

Run the equivalent explicit command when controlling Molecule directly:

```bash
uv run --group test --frozen molecule test -s qemu
```

What it does:

- Select exactly one `output/<nativearch>/*.qcow2`, or use an absolute `IMAGE_PATH`.
- Create a private temporary `~/.molecule-vm-*` directory and a QCOW2 overlay backed by the source image.
- Inject a transient `admin` SSH key and test-only passwordless sudo into the overlay using offline `virt-customize`.
- Boot native QEMU with EFI, then wait for SSH and sudo readiness on loopback.
- Check EFI boot, Fedora, Btrfs root, required packages, running services and absence of failed services.
- Stop the owned guest, then remove the overlay and temporary credentials.

Converge checks readiness rather than installing missing packages or repairing the image.
The source image remains unchanged; test credentials are never exported into it.
SSH host-key checking is disabled only for the disposable loopback guest with its private transient identity.
Do not reuse that SSH configuration for deployments.

## Host Runtime and Overrides

On Linux, run `virt-customize` on the host and use QEMU KVM by default.
On macOS, run QEMU on the host with HVF; run offline customization via `sudo virt-customize` in the running
Fedora Lima VM selected by `LIMA_INSTANCE` (default `kiwi-builder`), matching the build wrapper.
Keep source images under your home directory so the builder can access both the
backing image and the temporary overlay through its writable home share.

Use the native `qemu-system-x86_64` or `qemu-system-aarch64` binary. Cross-architecture testing is not provided.
Set `QEMU_ACCEL=tcg` explicitly to use slower software emulation when native acceleration is unavailable;
there is no silent local fallback:

```bash
QEMU_ACCEL=tcg uv run poe test
```

Configure runtime inputs as needed:

| Variable | Behavior |
| --- | --- |
| `IMAGE_PATH` | Absolute path to a standalone QCOW2 image; required for custom output roots or multiple images |
| `LIMA_INSTANCE` | macOS builder used for offline customization, default `kiwi-builder`; use the same value for builds and tests |
| `VM_SSH_PORT` | Loopback SSH forwarding port, default `2222`; allowed range `1024`–`65535` |
| `QEMU_ACCEL` | Linux `kvm` or macOS `hvf`; explicitly choose `tcg` for software emulation |
| `QEMU_EFI_CODE` | EFI code firmware file; set together with `QEMU_EFI_VARS` |
| `QEMU_EFI_VARS` | Matching EFI variables template; copied into private state before boot |

EFI firmware pairs are autodetected from common system and QEMU/Homebrew locations.
If detection fails, set both firmware overrides to existing, architecture-matched files from the same firmware distribution.
Use an image matching the native CPU; `IMAGE_PATH` does not enable cross-architecture testing.

## Inspect and Clean Up a Test Guest

Run lifecycle phases separately to retain a guest while investigating:

```bash
uv run --group test --frozen molecule create -s qemu
uv run --group test --frozen molecule converge -s qemu
uv run --group test --frozen molecule verify -s qemu
uv run --group test --frozen molecule destroy -s qemu
```

Inspect `console.log` and `supervisor.log` in the private state directory reported by the runtime on failure.
Do not delete overlays or source images while a guest is running. If cleanup cannot confirm shutdown, the runtime
retains private state rather than risk deleting a live disk; preserve that state while investigating.
Never deploy a test overlay: it contains temporary access credentials and test-only sudo policy.

## Helper Regression Tests

Run checks that do not require a built image or a running guest:

```bash
uv run poe check
node --test tests/test_artifact_cleanup.cjs tests/test_select_artifact.cjs
uv run --group test --frozen python -m unittest discover -s .github/workflows -p 'test_*.py'
```

Prefer `poe check` to install the required Molecule test dependencies even for no-VM schema checks.
For direct execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
CI runs these helper regressions on native Linux and macOS hosts; those jobs do not build or boot images.
Use the [CI and Automation guide](github-actions.md) to retrieve and test a Build artifact.
Passing helper tests does not establish that a build, KVM/HVF boot or physical deployment works.
