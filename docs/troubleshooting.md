# Troubleshooting

Common issues and fixes for Kiwi NG image workflows.

## Build Fails with Missing Tools

Symptom:

- command not found for `kiwi-ng`, `qemu-system-*`, or `ansible-playbook`

Fix:

- Install [host dependencies](building.md#prerequisites); Python packages do not replace KIWI system dependencies.
- Run `mise install` for pinned tools and `mise run setup` for frozen Python test dependencies and hook installation.
- On Fedora, install `kiwi-systemdeps` and the native QEMU, EFI firmware, `libguestfs-tools-c`, `openssh-clients` packages.
- On macOS, run `brew install mise qemu`, then `mise install` for Lima; run `virt-customize` inside the builder, not on macOS.
- Install system Java/Jing if KIWI description validation fails in hooks.
- Re-run the failed build or test command.

## macOS Build Cannot Start Virtualized Builder

Symptom:

- Lima instance does not start
- image creation exits early

Fix:

```bash
mise exec -- limactl list
mise run lima-cmd stop kiwi-builder
mise run lima-cmd start kiwi-builder
```

If startup still fails, inspect Lima logs and local virtualization/network requirements.
Only recreate the instance after preserving any needed builder-local files; deletion discards its VM disk:

```bash
mise run lima-cmd delete kiwi-builder
mise run build
```

Use the configured `LIMA_INSTANCE` instead of `kiwi-builder` in these commands if overriding the default builder.
Keep the same instance selection for builds and tests.

## Test Guest Fails to Connect Over SSH

Symptom:

- timeout while waiting for SSH port

Fix:

- Inspect `console.log` and `supervisor.log` in the reported private `~/.molecule-vm-*` directory.
- Confirm the chosen port is available; the default is loopback port `2222`.
- Destroy any retained guest, then choose another port:

```bash
uv run --group test --frozen molecule destroy -s qemu
VM_SSH_PORT=2223 mise run test
```

The base image deliberately has locked `admin`/`root` passwords and password SSH disabled.
Booting it manually does not inject an SSH key. Molecule injects a transient key and sudo policy only into its overlay.
For deployment, inject your real public key and provision access separately;
no deployment provisioner or cloud-init is provided.

## Wrong Architecture Binary

Symptom:

- runtime errors from QEMU binary mismatch

Fix:

- Build and test only the native host architecture; do not switch architectures to work around a missing binary.
- Install `qemu-system-x86_64` on x86 hosts or `qemu-system-aarch64` on ARM hosts.
- Let `mise run build` detect the host; `arm64`/`amd64` are normalized to `aarch64`/`x86_64`.
- Select an image and EFI firmware matching that native architecture; cross-builds are rejected.

## Image or EFI Firmware Not Found

Keep exactly one standalone QCOW2 in `output/<nativearch>/`, or set `IMAGE_PATH` to the absolute path of the intended image.
Custom `OUTPUT_DIR` builds require explicit `IMAGE_PATH` for tests. On macOS, keep that image under the shared home directory.

Install matching EFI firmware. If autodetection fails, set both `QEMU_EFI_CODE` and `QEMU_EFI_VARS` to existing,
matching firmware files; setting only one is rejected.

## macOS Overlay Customization Fails

Keep `kiwi-builder` running and ensure it can access the image and private test state through the writable home mount:

```bash
mise run lima-cmd start kiwi-builder
mise exec -- limactl shell kiwi-builder sudo dnf install -y libguestfs-tools-c
```

Store the checkout and images under your home directory. Check that `sudo virt-customize` can run in the Fedora builder;
Homebrew QEMU alone does not supply Linux libguestfs customization.
New builder provisioning installs libguestfs, but existing VMs need the explicit package update above.
Replace `kiwi-builder` with the configured `LIMA_INSTANCE` when using a non-default builder.

## QEMU Acceleration Unavailable

On Linux, enable virtualization and grant the testing user read/write access to `/dev/kvm`.
On macOS, check HVF availability. If hardware acceleration is unavailable, explicitly request software emulation:

```bash
QEMU_ACCEL=tcg mise run test
```

Expect slower boot and possible readiness timeouts; local tests do not silently fall back to TCG.

## Molecule Validation Fails

Symptom:

- scenario exits during create or verify phases

Fix:

- Inspect the failing phase and guest logs before removing state.
- Confirm packages and services are supplied by the image; converge does not repair missing packages.
- Destroy test resources, then retry without deleting the source image:

```bash
uv run --group test --frozen molecule destroy -s qemu
mise run test
```

If destruction cannot confirm shutdown, preserve the retained state and investigate the supervisor.
Do not delete a live overlay or its backing image. `mise run clean` removes default build outputs and is not VM cleanup.

## Helper Checks Fail to Import Molecule

Run `mise run check`, or explicitly use
`uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
The stdlib test runner still needs the test dependency group for Molecule schema validation;
plain `uv run python` can omit it in a fresh environment.

## CI Build Fails on Loop Devices or Mounts

The Build workflow uses a privileged Fedora 44 container on an Ubuntu runner, sharing the runner kernel.
Hosted-runner loop-device and mount compatibility is unverified. Inspect `losetup --find` and KIWI errors;
reproduce on a Fedora Linux host or the macOS Fedora Lima builder rather than assuming container privilege is sufficient.
Do not detach unrelated host loop devices to force a build to proceed.
