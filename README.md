# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Build a minimal Fedora base with KIWI NG for personal infrastructure, including laptops and servers.
Define minimum as boot, networking and Ansible prerequisites plus a secure baseline, not a complete machine role.
Keep applications, machine roles and site-specific configuration in
[`drts.casc`](https://github.com/drts01/ansible-collection).
Build and test natively on Linux or macOS; use QEMU to validate QCOW2 images before deployment.

## Build and Test Quickstart

On macOS, run:

```bash
brew install mise qemu
mise install
mise run setup
mise run doctor
mise run build
mise run test
```

On Fedora Linux, install the [build and test dependencies](docs/building.md#prerequisites), then run the same
build and test commands. Fedora 44 is the current image description.

## No-VM Contributor Quickstart

Install [mise](https://mise.jdx.dev/getting-started.html), then run helper regressions without building an image
or launching a guest:

```bash
mise install
mise run setup
mise run check-all
```

`check-all` aggregates the existing Python, Node artifact and workflow test suites; it does not run hooks.
Keep `mise run check` for Python-only regressions.
See the [Development Guide](docs/development.md) for aggregate checks, hook setup, Java/Jing prerequisites
and hook-applied formatting changes.

## Ownership

| Concern | Owner |
| --- | --- |
| Boot, EFI/Btrfs layout, networking and Ansible prerequisites | This repository |
| Secure base policy: locked passwords, SSH restrictions, SELinux and firewall | This repository |
| Image assembly, QCOW2 export and non-repairing base verification | This repository |
| Applications, machine roles and site-specific configuration | [`drts.casc`](https://github.com/drts01/ansible-collection) |
| Deployment identity and access provisioning | Operator-owned prerequisite; not implemented here |
| Collection compatibility validation | Proposed separate stage; not implemented here |

Justify base package and service additions against boot, networking, Ansible prerequisites or the secure baseline.
Route role-specific additions to the collection instead.

## Requirements

- Native Linux `x86_64`/`aarch64` or Apple Silicon macOS host; cross-architecture builds are rejected
- mise: pinned development tools; Lima is installed only on macOS
- Linux: KIWI system dependencies; QEMU, EFI firmware, libguestfs and OpenSSH for testing
- Apple Silicon macOS: Lima with the Fedora `kiwi-builder` VM and system QEMU
- Python: managed through `uv` using `.python-version`; Python dependencies locked in `uv.lock`
- Java/Jing: required for KIWI description validation in hooks

## Commands

```bash
mise run build [version] [arch]
mise run test
mise run check
mise run check-all
mise run check-artifacts
mise run check-workflows
mise run lint
mise run doctor
mise run clean
mise run lima-create
mise run lima-cmd [command] [instance]
```

Use `mise run lint` for `prek run --all-files`; review hook-applied changes.
Use `lima-create` and `lima-cmd` only on macOS.
See [toolchain setup](docs/development.md#setup) for tool pins and hook environments.

Use `mise run doctor [--scope build|test|all]` for read-only host prerequisite diagnostics
(default: `all`). It does not install tools or launch/start guests; diagnostics are not build or runtime proof.

## Handoff and Limits

- Build only the host architecture: `x86_64` or `aarch64` (`amd64`/`arm64` aliases are normalized).
- Find images in host `output/<arch>/`; set `OUTPUT_DIR` to change the output root.
  macOS exports only the QCOW2 image and optional package manifests from the builder.
- Test with Linux KVM or macOS HVF; explicitly set `QEMU_ACCEL=tcg` for slower software emulation.
- Keep deployment credentials separate: shipped `admin` and `root` passwords are locked and password SSH is disabled.
  Deployment access provisioning is not implemented; arrange a controlled access-provisioning process before applying
  `drts.casc`. No cloud-init is configured. See the [handoff contract](docs/building.md#handoff-to-drtscasc).
- Treat QCOW2 as the VM artifact. Physical-hardware deployment needs a future raw/installer workflow and hardware validation;
  no install-to-physical implementation is provided.
- Select architecture by CPU, not GUI requirements. Desktop composition is a separate image decision.

## Documentation

- [Docs Start Here](docs/README.md)
- [Building Guide](docs/building.md)
- [Testing Guide](docs/testing.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Development Guide](docs/development.md)
- [CI and Automation](docs/github-actions.md)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
