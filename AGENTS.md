# Project Instructions

## Objective and Sources

Build minimal Fedora images for personal infrastructure, including laptops and servers.
Support native `x86_64` and `aarch64` development and testing on Linux and macOS.
Treat QCOW2 as the current VM artifact; physical installation remains outside the implemented workflow.

Read `pyproject.toml` before changing tasks or dependency groups; use `uv.lock` for resolved versions.
Read `docs/building.md` before changing image assembly, architecture selection, output paths, or deployment access.
Read `docs/testing.md` before changing guest startup, authentication, firmware, verification, or teardown.
Read `docs/github-actions.md` before changing artifact selection, uploads, retention, or workflow behavior.
Read `docs/troubleshooting.md` when recovering a failed builder, guest, or export.

## Change Map

- Change image packages, Btrfs/EFI layout, and architecture profiles in `kiwi/fedora-44.kiwi` (YAML, despite the suffix).
- Change in-image account, SSH, service, and cleanup policy in `kiwi/config.sh`.
- Change native/Lima build dispatch in `scripts/build.sh`; keep exported deliverables in `scripts/export-image.sh`.
- Change the macOS Fedora builder in `lima/kiwi-builder.yaml`; Lima supplies Linux, not the finished test guest.
- Change guest lifecycle in `scripts/vm-test.py`; both hosts use this QEMU runtime.
- Change scenario wiring in `molecule/qemu/molecule.yml`; shared playbooks live in `molecule/default/`.
- Change image assertions in `molecule/default/verify-common.yml`; converge checks readiness without repairing the image.
- Keep artifact API logic in `scripts/select-artifact.cjs` and `scripts/artifact-cleanup.cjs` with Node tests.

## Invariants

Keep published disks unchanged during tests; customize and boot only disposable overlays.
Keep deployment identity separate from image contents; inject test keys and test-only sudo only into overlays.
Preserve loopback-only SSH forwarding and supervisor-confirmed shutdown before deleting runtime state.
Retain private state when shutdown cannot be confirmed; use the recovery guide rather than deleting live disks.
On macOS, keep source images under home for Lima access and keep Linux build environments on the guest filesystem.
Maintain one artifact contract across builder, exporter, CI packaging, and tests: host `output/<arch>/` by default.
Reject cross-architecture build requests; treat explicit QEMU TCG as a slower runtime option, not cross-build support.

## Validation

Run from the repository root:

```sh
uv run --frozen poe check
node --test tests/test_artifact_cleanup.cjs tests/test_select_artifact.cjs
uv run --group test --frozen python -m unittest discover -s .github/workflows -p 'test_*.py'
pre-commit run --all-files
```

Use `prek run --all-files` instead when that runner is installed; both consume `.pre-commit-config.yaml`.
Follow `docs/development.md` for setup, Java/Jing prerequisites, and hook side effects.
Write Python regressions with stdlib `unittest` in `tests/test_*.py`; use Node's native test runner for `tests/test_*.cjs`.
Exercise error paths with mocks/shims before running privileged builds or guests.
When runtime validation is required, run `uv run --frozen poe build`, then `uv run --frozen poe test`.
Report helper tests, real image builds, VM boots, and physical-hardware validation as separate evidence.

## Implementation Conventions

Use Bash strict mode and argument arrays for build commands; pass subprocess arguments as lists in Python.
Propagate failed builds, customization, verification, and cleanup instead of turning failures into success reports.
Follow scoped Conventional Commits for requested commits; keep each commit to one logical change and its tests.
Inspect `.pre-commit-config.yaml` for actual formatting and lint rules; review hook-applied changes.
