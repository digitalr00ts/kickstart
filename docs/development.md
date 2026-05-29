# Development Guide

This guide describes the local workflow for contributors.

## Setup

```bash
uv sync
pre-commit install
```

## Daily Workflow

1. Create a branch.
2. Make code changes.
3. Run validation locally.
4. Open a pull request.

## Local Validation Commands

```bash
pre-commit run --all-files
uv run poe test ansible-collection
uv run poe test qemu
```

For a full build pass:

```bash
uv run poe build-full
```

## Code Areas

- `kiwi/`: image descriptions and in-image configuration script
- `ansible/`: provisioning playbook and collection requirements
- `scripts/`: build and provisioning wrappers
- `molecule/`: scenario lifecycle and verification playbooks
- `docs/`: operator and contributor documentation

## Quality Expectations

- keep shell scripts strict with `set -euo pipefail`
- keep docs aligned with executable commands
- avoid committing generated artifacts under `output/`
