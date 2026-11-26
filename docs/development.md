# Development Guide

This guide describes the local workflow for contributors.

## Setup

```bash
uv sync --group test --frozen
uv tool install pre-commit
pre-commit install
```

Use `prek install` and `prek run --all-files` instead if you already use `prek`; both read `.pre-commit-config.yaml`.
Install the [host build/test dependencies](building.md#prerequisites) before running image workflows.
Full hook runs include KIWI description validation, which requires Java/Jing; CI installs `jing`.

## Daily Workflow

1. Create a branch.
2. Make code changes.
3. Run validation locally.
4. Open a pull request.

## Local Validation Commands

```bash
pre-commit run --all-files
uv run poe check
node --test tests/test_artifact_cleanup.cjs tests/test_select_artifact.cjs
uv run --group test --frozen python -m unittest discover -s .github/workflows -p 'test_*.py'
```

Prefer `uv run poe check` for Python regressions: the task installs the test dependency group and uses the frozen lockfile.
For direct execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
The runner is stdlib `unittest`, but schema checks require Molecule from the test group even without a VM.
Install Node.js for the artifact-cleanup and artifact-selection suites.
These helper checks do not build or boot an image. Hooks can apply formatting fixes; review the resulting diff.

For a full native build and VM test pass:

```bash
uv run poe build
uv run poe test
```

For explicit Molecule lifecycle commands, use `uv run --group test --frozen molecule test -s qemu` and
`uv run --group test --frozen molecule destroy -s qemu`.
See the [Testing Guide](testing.md) for image selection and acceleration.

## Code Areas

- `kiwi/`: image descriptions and in-image configuration script
- `scripts/`: build wrapper, filtered image export, disposable QEMU runtime and artifact helpers
- `tests/`: helper and lifecycle regression tests
- `molecule/`: scenario lifecycle and verification playbooks
- `docs/`: operator and contributor documentation

## Quality Expectations

- keep shell scripts strict with `set -euo pipefail`
- keep docs aligned with executable commands
- avoid committing generated artifacts under `output/`
