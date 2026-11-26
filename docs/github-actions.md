# CI and Automation

Use the repository workflows to check source, build native images, test downloaded artifacts and clean expired artifacts.
Workflow definitions are not evidence of a successful end-to-end image build or boot.

## Workflow Layout

| Workflow | Trigger | Responsibility |
| --- | --- | --- |
| `ci.yaml` | Push and pull request | Native Linux/macOS no-VM regressions; separate Linux pre-commit hooks through `prek` |
| `docs.yml` | Push to `trunk`, pull request; manual dispatch | Strict documentation build; publish trusted `trunk` builds to GitHub Pages |
| `build.yml` | Selected source changes; manual dispatch | Native Fedora 44 image build and artifact upload |
| `test-image.yml` | Successful trusted `main` push build; manual dispatch | Artifact retrieval, integrity checks and real Molecule VM validation |
| `cleanup-artifacts.yml` | Weekly schedule; manual dispatch | Expiry-aware artifact cleanup or preview |

## Source Checks

```bash
mise install
mise run setup
mise run lint
```

Install mise first; use `mise run lint` for `prek run --all-files`. Install system Java/Jing for KIWI description validation.
Share tool pins from `mise.toml` and `mise.lock` between local checks and CI through `mise exec` system hooks;
retain isolated KIWI and Ansible hook environments. See [Development](development.md#local-validation-commands)
for manual-stage checks and hook side effects.
Run lightweight helper regressions with:

```bash
mise run check-all
```

Use `mise run check-all` for Python, Node artifact and workflow regressions without hooks; `mise install` supplies Node.js.
Retain `mise run check` for the Python-only suite; it installs the test dependency group with the frozen lockfile.
For direct execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
CI runs helper regressions on `ubuntu-24.04` and `macos-latest`; these mocked/schema checks do not validate
image assembly, KVM/HVF boot or physical hardware. The pre-commit job runs separately on Linux.

## Documentation Publishing

Run `mise run docs-build` to build the Zensical site with frozen docs dependencies and fail on warnings.
Use `docs.yml` to check pull requests and publish successful builds from `trunk`, without building images or launching VMs.
Manual dispatch also publishes only when the selected ref is `trunk`; pull requests never upload or deploy Pages artifacts.
Upload only generated `site/` output as the Pages artifact with one-day retention; keep it untracked.
Grant `pages: write` and `id-token: write` only to the deploy job, after the read-only build succeeds.
Serialize deployments in the `github-pages` concurrency group without cancelling an active deployment.

Enable the site once under **Settings → Pages → Build and deployment → Source → GitHub Actions**.
Configure the `github-pages` environment to permit deployments only from `trunk`.
Push the workflow to `trunk`, or dispatch **Documentation** from `trunk`, then check the deployment URL:
<https://digitalr00ts.github.io/kickstart/>. The URL becomes available only after a successful deployment.
Treat published documentation as public; do not include credentials or private operational data in `docs/`.
To roll back, revert the documentation change on `trunk` and let the workflow redeploy.
See [Documentation Site](development.md#documentation-site) for local preview and configuration.

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

Run image tests automatically after a successful **Build** triggered by a same-repository push to `main`.
Exclude pull-request builds, fork builds, unsuccessful builds and other branches. Automatic runs test the default `x86_64`
artifact from that exact completed build run and check out its source commit. This adds a VM-test job per qualifying build;
it is a post-build check, not a prerequisite for uploading the build artifact. Keep token permissions read-only.
The workflow must exist on the default branch for GitHub to deliver completion events.

Dispatch **Test Kiwi NG Image** manually with the native image architecture. Optionally provide a successful Build `run_id`
and exact `artifact_name` for reproducible selection. Without a run ID, search successful same-repository Build runs
for the latest matching unexpired image artifact. Reject ambiguous matches and expired or wrong-architecture artifacts.
Download from the selected run using its run ID, not from the current Test workflow run.

Extract exactly one image with the workflow's safe archive helper. Check that it is standalone QCOW2 without external
backing/data files, then run `qemu-img check`. Install pinned QEMU and `uv` through mise;
install EFI firmware and libguestfs through the system package manager, then sync project test dependencies;
run the real Molecule `qemu` scenario, not a placeholder validation command.
Use KVM when accessible; the workflow explicitly requests TCG otherwise. TCG can be substantially slower.

Run the same scenario locally with:

```bash
mise run test
```

The workflow attempts Molecule destruction after tests and reports actual integrity, test and cleanup outcomes.
On failure, upload only `console.log` and `supervisor.log` after the cleanup attempt, with seven-day retention.
The runtime snapshots these logs outside private state before deleting it, including on startup failure; missing logs are ignored.
Never upload overlays, keys or the full runtime directory. Logs are not redacted; treat them as diagnostic artifacts subject to
repository artifact access controls.
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
