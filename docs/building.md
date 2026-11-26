# Building Images

Build Fedora images with KIWI NG on native Linux or through the Fedora `kiwi-builder` Lima VM on macOS.

## Prerequisites

Use an `x86_64` or `aarch64` host. Prefer Fedora Linux for native builds; other Linux distributions need equivalent
KIWI system dependencies and are not validated by these instructions. `uv` manages Python 3.14+ and the Python KIWI package;
it does not install host disk, mount or virtualization tools. Allow `sudo` for privileged KIWI operations.

On Fedora, install build dependencies:

```bash
sudo dnf install kiwi-systemdeps uv
```

For local VM tests, also install QEMU, matching EFI firmware, libguestfs and SSH clients. For example:

```bash
sudo dnf install qemu-img qemu-system-x86-core edk2-ovmf libguestfs-tools-c openssh-clients
```

On `aarch64`, use `qemu-system-aarch64-core` and `edk2-aarch64` instead of the x86 QEMU/firmware packages.
Confirm package availability for your Fedora release and enabled repositories; names can vary.
Enable read/write access to `/dev/kvm` for the testing user, or explicitly request `QEMU_ACCEL=tcg`.

On macOS, install host tools:

```bash
brew install lima qemu uv
```

Keep the checkout and test images under your home directory, which the builder shares writable.
The build wrapper creates or starts `kiwi-builder` using `lima/kiwi-builder.yaml`.
KIWI runs inside Fedora, not on the macOS host. Existing builders may need the test customization dependency:

```bash
limactl shell kiwi-builder sudo dnf install -y libguestfs-tools-c
```

Run that command only after the builder exists and is running; replace `kiwi-builder` if using another `LIMA_INSTANCE`.
New builders install this dependency during provisioning; existing VMs need the explicit update.
See the [Testing Guide](testing.md) for runtime requirements.

## Build Image

```bash
uv run poe build
```

Build with explicit version and architecture, choosing only the command that matches the host CPU:

```bash
# On an x86_64 host:
uv run poe build 44 x86_64
# On an aarch64/Apple Silicon host:
uv run poe build 44 aarch64
```

The wrapper normalizes `amd64` to `x86_64` and `arm64` to `aarch64`, and rejects cross-architecture requests.
Fedora 44 is the supplied description; another version requires a matching image description, not just a version argument.

## Build Outputs

Artifacts are written to:

- `output/x86_64/` on x86 hosts
- `output/aarch64/` on ARM hosts

On Linux, KIWI builds directly into the architecture directory. On macOS, build in a temporary directory under
`/opt/kiwi-build` on the builder's Linux filesystem, then use `scripts/export-image.sh` to export exactly one QCOW2
and optional `*.packages` manifests to the host output architecture directory. Do not export the KIWI build root or
intermediate disks. The macOS wrapper requires the host architecture output directory to be empty before export;
if it is not, preserve or move existing artifacts and retry. Failed exports retain guest staging for investigation.
This keeps privileged image assembly off the shared macOS filesystem while retaining host-visible deliverables.

Inspect the output directory directly. Remove default local build artifacts only after destroying test guests:

```bash
uv run --group test --frozen molecule destroy -s qemu
uv run poe clean
```

`clean` deletes default `output/`, `build/`, `.kiwi-*` and top-level QCOW2 files; it does not clean a custom output root.

## Environment Overrides

Useful environment variables:

- `OUTPUT_DIR`: override the host output root using a relative or absolute path; the wrapper appends `<arch>/`
- `LIMA_INSTANCE`: select the macOS builder name, default `kiwi-builder`; use the same value for builds and tests

For example, run `OUTPUT_DIR=images uv run poe build` to export to `images/<arch>/`.
Quote paths containing spaces, such as `OUTPUT_DIR="images for testing" uv run poe build`.
Set an absolute `IMAGE_PATH` when testing images outside default `output/<arch>/`.

## Platform and Deployment Boundaries

Retain KIWI for image assembly, Lima for the Linux build environment on macOS, QEMU for guest validation,
and `uv`/Poe/Molecule for dependency and task orchestration. Build and test natively to avoid cross-architecture
emulation costs and mismatched platform assumptions. This supports both Linux and macOS infrastructure workflows;
it does not select a desktop environment. Choose the CPU architecture independently of GUI package composition.

Ship locked `admin` and `root` passwords with password SSH disabled. Before deploying an image, inject your actual
public key and provision the intended account, SSH and sudo policies through a controlled offline or deployment process.
The repository does not configure cloud-init or implement a deployment provisioner. Test-only keys and passwordless sudo
exist only in disposable test overlays; they do not make the shipped image accessible.

Use QCOW2 for QEMU VM validation. Deploying to a physical laptop or server requires a future raw/installer artifact,
a safe installation process, and validation of firmware, storage, networking and hardware-specific drivers.
Do not write a QCOW2 file directly to a physical disk or treat VM success as hardware validation.
No install-to-physical workflow or hardware compatibility guarantee is implemented.
