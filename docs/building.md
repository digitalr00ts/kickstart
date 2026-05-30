# Building Images

This guide covers image creation with Kiwi NG.

## Prerequisites

- `uv`
- `kiwi-ng`
- `qemu-system-*`

On macOS, install Lima:

```bash
brew install lima
```

## Build Image

```bash
uv run poe build
```

Build with explicit version and architecture:

```bash
uv run poe build 44 x86_64
uv run poe build 44 aarch64
```

## Build Outputs

Artifacts are written to:

- `output/kiwi-x86_64/`
- `output/kiwi-aarch64/`

Use status and cleanup utilities:

```bash
uv run poe status
uv run poe clean
```

## Environment Overrides

Useful environment variables:

- `OUTPUT_DIR`: override output directory
- `MOLECULE_POLICY_MODE`: influence test policy behavior
