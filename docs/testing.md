# Testing Guide

Validate a built Fedora QCOW2 image with Molecule and native QEMU on Linux or macOS.
Install the [host dependencies](building.md#prerequisites) first.
These checks validate a VM, not physical hardware.
Run `mise run doctor --scope test` for read-only host prerequisite diagnostics;
use `--scope build` for build prerequisites or omit `--scope` for the default `all` scope.
Doctor does not install tools or create, start or launch guests, including the Lima builder.
Diagnostics are not runtime proof.

## Image Validation Scenario

Build an image, then run the Molecule scenario:

```bash
mise run build
mise run test
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

Select `-s qemu` for explicit lifecycle commands; it is the only runnable scenario.
Keep shared playbooks under `molecule/default/`; that directory no longer defines a default scenario.
Bound the completed-boot check to 240 seconds; a guest that remains activating fails verification.
Gather only distribution facts through setup; gather packages and services separately.

Converge checks readiness rather than installing missing packages or repairing the image.
The source image remains unchanged; test credentials are never exported into it.
SSH host-key checking is disabled only for the disposable loopback guest with its private transient identity.
Do not reuse that SSH configuration for deployments.

## Host Runtime and Overrides

On Linux, install pinned QEMU with `mise install`, run `virt-customize` on the host and use QEMU KVM by default.
Keep firmware, libguestfs and KVM permissions as host prerequisites; use Homebrew QEMU on macOS.
The pinned `takumin/qemu-bin` release supports glibc Linux hosts (minimum glibc 2.27).
Upstream does not test its ARM64 binary.
Require native Linux `x86_64` and `aarch64` KVM image boots before treating this toolchain as runtime-validated;
helper regressions and successful installation alone do not establish compatibility.
On macOS, run QEMU on the host with HVF;
run offline customization via `sudo virt-customize` in the running Fedora Lima VM selected by `LIMA_INSTANCE`
(default `kiwi-builder`), matching the build wrapper.
Keep source images under your home directory so the builder can access both the backing image
and the temporary overlay through its writable home share.

Use the native `qemu-system-x86_64` or `qemu-system-aarch64` binary.
Cross-architecture testing is not provided.
Set `QEMU_ACCEL=tcg` explicitly to use slower software emulation when native acceleration is unavailable;
there is no silent local fallback:

```bash
QEMU_ACCEL=tcg mise run test
```

Configure runtime inputs as needed:

| Variable        | Behavior                                                                                                                         |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `IMAGE_PATH`    | Absolute path to a standalone QCOW2 image; required for custom output roots or multiple images                                   |
| `LIMA_INSTANCE` | macOS builder used for offline customization, default `kiwi-builder`; use the same value for builds and tests                    |
| `VM_SSH_PORT`   | Loopback SSH forwarding port, default `2222`; allowed range `1024`–`65535`                                                       |
| `QEMU_ACCEL`    | Linux `kvm` or macOS `hvf`; explicitly choose `tcg` for software emulation                                                       |
| `VM_LOG_DIR`    | Optional directory for teardown snapshots of only `console.log` and `supervisor.log`; CI sets this outside private runtime state |
| `QEMU_EFI_CODE` | EFI code firmware file; set together with `QEMU_EFI_VARS`                                                                        |
| `QEMU_EFI_VARS` | Matching EFI variables template; copied into private state before boot                                                           |

EFI firmware pairs are autodetected from common system and QEMU/Homebrew locations.
If detection fails, set both firmware overrides to existing,
architecture-matched files from the same firmware distribution.
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
Do not delete overlays or source images while a guest is running.
If cleanup cannot confirm shutdown, the runtime retains private state rather than risk deleting a live disk;
preserve that state while investigating.
Never deploy a test overlay: it contains temporary access credentials and test-only sudo policy.
Set `VM_LOG_DIR` before creation and destruction to preserve logs even when startup failure triggers cleanup.
Snapshot logs after attempting supervisor-confirmed shutdown, including when shutdown fails;
retain live state on unconfirmed shutdown.
Do not upload the private state directory, overlays or keys.
Log snapshots are not redacted; review their contents
before sharing outside the repository's normal artifact access boundary.

## Proposed Collection Compatibility Stage (Not Implemented)

Keep base image validation independent of application
and machine-role customization in [`drts.casc`](https://github.com/drts01/ansible-collection).
The current scenario disables Galaxy dependency installation and only checks base readiness and image assertions;
it does not apply the collection, test its idempotence or verify effective SSH policy.
Deployment access provisioning is also not implemented; no deployment commands are provided here.

Require these acceptance criteria before treating a future, separate compatibility stage as implemented:

1. Pin the collection to an immutable revision or exact release version and record the resolved version
   and dependencies with the base artifact identity, Fedora release and native architecture.
   Do not test a floating branch as a release gate.
2. Create a fresh disposable overlay from the unchanged base artifact for every compatibility run.
   Inject only transient test identity and test-only privilege policy;
   keep deployment credentials and site secrets outside published artifacts.
3. Run non-repairing base verification before any collection converge.
   Fail immediately on missing base prerequisites;
   never let collection tasks install or repair them to hide an invalid base.
4. Converge an explicitly selected collection role set with documented test inputs, verify the intended result,
   then converge again and require zero unexpected changes as the idempotence gate.
   Report compatibility separately from base validation;
   a collection failure must not be reported as a successful base-plus-collection result.
5. Verify effective SSH policy before and after collection converge, including connection-specific `Match` behavior:
   disable password and keyboard-interactive authentication and root login;
   retain public-key authentication and working unprivileged key access with the intended sudo policy.
   Inspect effective daemon configuration, not only drop-in text.
6. Confirm the source artifact remains unchanged.
   Stop the guest with supervisor-confirmed shutdown before cleanup;
   retain private state if shutdown cannot be confirmed.
   Never publish, export or deploy the customized test overlay, its transient keys or test-only sudo policy.

Keep application, machine-role and site-specific assertions with the collection compatibility stage,
not base verification.
VM compatibility evidence does not establish deployment provisioning or physical-hardware support.

## Helper Regression Tests

Run checks that do not require a built image or a running guest:

```bash
mise run check-all
```

`check-all` aggregates the existing Python, Node artifact and workflow suites without running hooks;
run `mise install` and `mise run setup` first to install pinned tools and Python test dependencies.
Use `mise run check` for Python-only regressions with the required Molecule test dependencies,
even for no-VM schema checks.
See the [Development Guide](development.md) for aggregate checks and hooks.
For direct execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
CI runs these helper regressions on native Linux and macOS hosts; those jobs do not build or boot images.
Use the [CI and Automation guide](github-actions.md) to retrieve and test a Build artifact.
Passing helper tests does not establish that a build, KVM/HVF boot or physical deployment works.
