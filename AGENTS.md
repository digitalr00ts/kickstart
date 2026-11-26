# Project Instructions

## Objective and Sources

Build minimal Fedora images for personal infrastructure, including laptops and servers.
Support native `x86_64` and `aarch64` development and testing on Linux, and `aarch64` on macOS.
Treat QCOW2 as the current VM artifact; physical installation remains outside the implemented workflow.

Read `mise.toml` and `mise.lock` before changing tasks or tool pins.
Read `pyproject.toml` before changing Python dependency groups; retain `uv`, `.python-version` and `uv.lock` for Python management.
Read `docs/building.md` before changing image assembly, architecture selection, output paths, or deployment access.
Read `docs/testing.md` before changing guest startup, authentication, firmware, verification, or teardown.
Read `docs/github-actions.md` before changing artifact selection, uploads, retention, or workflow behavior.
Read `docs/troubleshooting.md` when recovering a failed builder, guest, or export.

## Ownership

Keep this image minimal: boot, networking and Ansible prerequisites plus a secure baseline.
Route applications, machine roles and site-specific configuration to
[`drts.casc`](https://github.com/drts01/ansible-collection).
Require a base-purpose justification for every package or service addition.
Keep base verification non-repairing; fail on missing prerequisites instead of installing or configuring them.
Keep collection compatibility in a separate stage; follow the proposed acceptance criteria in `docs/testing.md`.
Treat deployment access provisioning, cloud-init and physical installation as unimplemented here.

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
mise install
mise run setup
mise run check-all
mise run lint
```

Use `mise run setup` for frozen test dependency sync and `prek install`; use `mise run lint` for `prek run --all-files`.
Share mise tool pins through system hooks using `mise exec`; retain the isolated Ansible hook environment.
Run KIWI validation through `mise run check-kiwi` using the frozen uv build dependency group.
Use `check-all` for Python, Node artifact and workflow tests without hooks; retain `check` for Python-only tests.
Follow `docs/development.md` for aggregate checks, setup, Java/Jing prerequisites, and hook side effects.
Use `mise run doctor [--scope build|test|all]` (default `all`) for read-only host prerequisite diagnostics.
Keep diagnostics separate from runtime proof; doctor does not install tools or launch/start guests.
Write Python regressions with stdlib `unittest` in `tests/test_*.py`; use Node's native test runner for `tests/test_*.cjs`.
Exercise error paths with mocks/shims before running privileged builds or guests.
When runtime validation is required, run `mise run build`, then `mise run test`.
Report helper tests, real image builds, VM boots, and physical-hardware validation as separate evidence.

## Implementation Conventions

Use Bash strict mode and argument arrays for build commands; pass subprocess arguments as lists in Python.
Propagate failed builds, customization, verification, and cleanup instead of turning failures into success reports.
Follow scoped Conventional Commits for requested commits; keep each commit to one logical change and its tests.
Inspect `.pre-commit-config.yaml` for actual formatting and lint rules; review hook-applied changes.
