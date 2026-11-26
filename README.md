# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Build minimal Fedora images with KIWI NG for your own infrastructure, including laptops and servers.
Build and test natively on Linux or macOS; use QEMU to validate QCOW2 images before deployment.

## Quick Start

On macOS, run:

```bash
brew install lima qemu uv
uv run poe build
uv run poe test
```

On Fedora Linux, install the [build and test dependencies](docs/building.md#prerequisites), then run the same
build and test commands. Fedora 44 is the current image description.

## Requirements

- Native `x86_64` or `aarch64` host; cross-architecture builds are rejected
- Linux: KIWI system dependencies and `uv`; QEMU, EFI firmware, libguestfs and OpenSSH for testing
- macOS: Lima with the Fedora `kiwi-builder` VM, QEMU and `uv`
- Python 3.14 or newer, managed through `uv`

## Commands

```bash
uv run poe build [version] [arch]
uv run poe test
uv run poe check
uv run poe clean
```

## Notes

- Build only the host architecture: `x86_64` or `aarch64` (`amd64`/`arm64` aliases are normalized).
- Find images in host `output/<arch>/`; set `OUTPUT_DIR` to change the output root.
  macOS exports only the QCOW2 image and optional package manifests from the builder.
- Test with Linux KVM or macOS HVF; explicitly set `QEMU_ACCEL=tcg` for slower software emulation.
- Keep deployment credentials separate: shipped `admin` and `root` passwords are locked and password SSH is disabled.
  Inject your actual deployment public key and provision access before deploying; no cloud-init is configured.
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
