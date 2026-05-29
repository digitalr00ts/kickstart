# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Automated Fedora image builds with Kiwi NG and Ansible provisioning.

## Quick Start

```bash
brew install lima
uv run poe build-kiwi
uv run poe build-full
```

## Requirements

- Kiwi NG
- QEMU
- Ansible 2.15+
- uv

## Commands

```bash
uv run poe build-kiwi [version] [arch]
uv run poe provision-image <image>
uv run poe build-full [version] [arch]
uv run poe kiwi-clean
uv run poe test qemu
uv run poe test ansible-collection
uv run poe clean
uv run poe status
```

## Notes

- Supported architectures: x86_64 and aarch64
- Output images are written under output/kiwi-*/
- Local collection development is supported via ANSIBLE_COLLECTIONS_PATH

## Documentation

- [Docs Start Here](docs/README.md)
- [Building Guide](docs/building.md)
- [Testing Guide](docs/testing.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Development Guide](docs/development.md)
- [CI and Automation](docs/github-actions.md)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
