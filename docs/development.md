# Development Guide

Change the minimal Fedora base here; keep applications, machine roles and site-specific configuration in
[`drts.casc`](https://github.com/drts01/ansible-collection). Read the [ownership boundary](../README.md#ownership)
before adding packages or services.

## Setup

```bash
uv sync --group test --frozen
uv tool install pre-commit
pre-commit install
```

Use `prek install` and `prek run --all-files` instead if you already use `prek`; both read `.pre-commit-config.yaml`.
Install Node.js for the artifact helper tests. No built image, QEMU or Lima guest is needed for helper regressions.
Install the [host build/test dependencies](building.md#prerequisites) only when running image workflows.
Full hook runs include KIWI description validation, which requires Java/Jing; CI installs `jing`.

## Daily Workflow

1. Create a branch.
2. Make focused changes and add helper regressions for error paths before using privileged builds or guests.
3. Run `uv run --frozen poe check-all`, then run hooks and review formatting changes.
4. Build and boot an image when changing image contents, assembly or guest runtime behavior.
5. Report helper tests, builds and guest boots separately in the pull request; VM tests do not validate physical hardware.

## Local Validation Commands

```bash
uv run --frozen poe check-all
pre-commit run --all-files
```

Run `check-all` to execute Python, Node artifact and workflow suites in sequence, stopping on a failure.
Keep hooks separate: they may download tools, validate KIWI descriptions and apply formatting fixes; review the diff.
Use these tasks for narrower feedback:

| Task | Scope |
| --- | --- |
| `uv run --frozen poe check` | Python helper regressions in `tests/` |
| `uv run --frozen poe check-artifacts` | Node artifact-cleanup and artifact-selection regressions |
| `uv run --frozen poe check-workflows` | Python workflow helper regressions |

For direct Python execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
The runner is stdlib `unittest`, but schema checks require Molecule from the test group even without a VM.
These helper checks do not build or boot an image.

## Host Prerequisite Diagnostics

Run the read-only doctor before image work:

```bash
uv run --frozen poe doctor
uv run --frozen poe doctor --scope build
uv run --frozen poe doctor --scope test
```

Use the default `all` scope to check both build and test prerequisites. Fix reported failures, then rerun the doctor.
The checker reports supported OS/CPU, executable availability, macOS checkout/image path constraints, EFI firmware lookup,
valid acceleration selection and Linux KVM permissions. On macOS, the test scope queries QEMU's accelerator list with a
bounded `-accel help` command; it does not boot a guest. No built image is required.

The doctor does not install packages, invoke sudo, start Lima, run guest commands or change image/runtime files.
The surrounding `uv run` command can still synchronize the Python environment from the frozen lockfile.
Passing diagnostics does not prove complete KIWI system dependencies, matching firmware contents, Lima guest readiness,
usable acceleration or a successful build/boot. Follow the build/test guides for runtime proof.

## Image Validation

For a full native build and VM test pass:

```bash
uv run --frozen poe build
uv run --frozen poe test
```

For explicit Molecule lifecycle commands, use `uv run --group test --frozen molecule test -s qemu` and
`uv run --group test --frozen molecule destroy -s qemu`.
See the [Testing Guide](testing.md) for image selection and acceleration.

## Code Areas

- `kiwi/`: image descriptions and in-image configuration script
- `scripts/`: build wrapper, filtered image export, read-only host doctor, disposable QEMU runtime and artifact helpers
- `tests/`: helper and lifecycle regression tests
- `molecule/`: scenario lifecycle and verification playbooks
- `docs/`: operator and contributor documentation

## Quality Expectations

- keep shell scripts strict with `set -euo pipefail`
- keep docs aligned with executable commands
- avoid committing generated artifacts under `output/`
- keep base verification non-repairing and collection compatibility separate; use the
  [proposed collection acceptance criteria](testing.md#proposed-collection-compatibility-stage-not-implemented)
- review optional KIWI `*.packages` manifests when changing image packages; justify growth against the base purpose
