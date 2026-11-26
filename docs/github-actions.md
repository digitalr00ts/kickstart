# CI and Automation

Use the repository workflows to check source, build native images, test downloaded artifacts and clean expired artifacts.
Workflow definitions are not evidence of a successful end-to-end image build or boot.

## Workflow Layout

| Workflow | Trigger | Responsibility |
| --- | --- | --- |
| `ci.yaml` | Push and pull request | Native Linux/macOS no-VM regressions; separate Linux pre-commit hooks through `prek` |
| `build.yml` | Selected source changes; manual dispatch | Native Fedora 44 image build and artifact upload |
| `test-image.yml` | Manual dispatch | Artifact retrieval, integrity checks and real Molecule VM validation |
| `cleanup-artifacts.yml` | Weekly schedule; manual dispatch | Expiry-aware artifact cleanup or preview |

## Source Checks

```bash
uv tool install pre-commit
pre-commit run --all-files
```

Use `prek run --all-files` if already installed. Install Java/Jing for KIWI description validation.
Run lightweight helper regressions with:

```bash
uv run --frozen poe check-all
```

Use `poe check-all` for Python, Node artifact and workflow regressions without hooks; install Node.js.
Retain `poe check` for the Python-only suite; it installs the test dependency group with the frozen lockfile.
For direct execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
CI runs helper regressions on `ubuntu-24.04` and `macos-latest`; these mocked/schema checks do not validate
image assembly, KVM/HVF boot or physical hardware. The pre-commit job runs separately on Linux.

## Native Image Builds

Dispatch **Build** with Fedora version `44` and architecture `x86_64` or `aarch64`.
The workflow chooses a native Ubuntu runner (`ubuntu-24.04` or `ubuntu-24.04-arm`) and runs KIWI inside a
privileged `fedora:44` container. Automatic builds default to `x86_64`; there is no cross-build mode.

Privileged containers share the runner kernel. Loop-device allocation and mounts must work on that kernel;
hosted-runner compatibility is unverified. Do not describe this as Fedora VM isolation or a validated build environment.
The workflow checks native architecture and available loop support before building; runtime validation is still required.

Package exactly one QCOW2 from `output/<arch>/`, plus optional package manifests, as a `.tar.zst` archive.
Image artifacts use `fedora-<version>-<arch>-<short-sha>` names and 30-day retention.
Build metadata is uploaded separately with 90-day retention.

## Artifact Retrieval and VM Validation

Dispatch **Test Kiwi NG Image** with the native image architecture. Optionally provide a successful Build `run_id`
and exact `artifact_name` for reproducible selection. Without a run ID, search successful same-repository Build runs
for the latest matching unexpired image artifact. Reject ambiguous matches and expired or wrong-architecture artifacts.
Download from the selected run using its run ID, not from the current Test workflow run.

Extract exactly one image with the workflow's safe archive helper. Check that it is standalone QCOW2 without external
backing/data files, then run `qemu-img check`. Install QEMU, EFI firmware, libguestfs and project test dependencies;
run the real Molecule `qemu` scenario, not a placeholder validation command.
Use KVM when accessible; the workflow explicitly requests TCG otherwise. TCG can be substantially slower.

Run the same scenario locally with:

```bash
uv run --group test --frozen molecule test -s qemu
```

The workflow attempts Molecule destruction after tests and reports actual integrity, test and cleanup outcomes.
Artifact integrity alone does not establish guest boot success. See [Testing](testing.md) for overlay isolation and logs.

## Artifact Cleanup

Run scheduled cleanup weekly on Sunday at 02:00 UTC. Scheduled runs delete eligible expired artifacts;
manual dispatch defaults to preview with `dry_run: true`.

Honor each artifact's declared expiry by default, with fallback retention of 30 days for images and 90 days for metadata.
Use manual `retention_days` only for an intentional global override from 1 to 365 days; leave it empty to preserve
normal artifact-specific retention. Preview the candidates before disabling dry-run.
Cleanup requires `actions: write`; artifact retrieval uses `actions: read`.

## Caching Tips

- cache Python dependencies used by `uv`
- avoid caching generated image artifacts unless release jobs require it

## Failure Triage Order

1. Read pre-commit output first.
2. Check runner architecture, container loop/mount support and KIWI build logs.
3. Check artifact selection, download, extraction and QCOW2 integrity output.
4. Check Molecule create/converge/verify and cleanup logs.
5. Reproduce locally with the same image and runtime overrides.
