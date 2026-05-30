# Fedora Image Builder

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

Automated Fedora image builds with Kiwi NG.

## Quick Start

```bash
brew install lima
uv run poe build
```

## Requirements

- Kiwi NG
- QEMU
- uv

## Commands

```bash
uv run poe build [version] [arch]
uv run poe test
uv run poe clean
uv run poe status
```

## Notes

- Supported architectures: x86_64 and aarch64
- Output images are written under output/kiwi-*/

## Documentation

- [Docs Start Here](docs/README.md)
- [Building Guide](docs/building.md)
- [Testing Guide](docs/testing.md)
- [Troubleshooting Guide](docs/troubleshooting.md)
- [Development Guide](docs/development.md)
- [CI and Automation](docs/github-actions.md)

## License

This project is licensed under the Apache License 2.0. See [LICENSE](LICENSE) for details.
