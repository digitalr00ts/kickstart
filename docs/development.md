# Development Guide

Change the minimal Fedora base here; keep applications,
machine roles and site-specific configuration in [`drts.casc`](https://github.com/drts01/ansible-collection).
Read the [ownership boundary](https://github.com/digitalr00ts/kickstart/blob/trunk/README.md#ownership)
before adding packages or services.

## Setup

Install [mise](https://mise.jdx.dev/getting-started.html), then run from the repository root:

```bash
mise install
mise run setup
```

Use `mise.toml` for task definitions and tool version declarations; commit `mise.lock` for resolved tool pins.
Run `mise install` to install the pinned `uv`, `prek`, Node.js, Ruff, `jactionlint`, `tombi`, `rumdl`,
`aqua:owenlamont/ryl`, `aqua:ewhauser/shuck`, `zizmor` and `aqua:crate-ci/typos` tools,
plus `aqua:takumin/qemu-bin` on Linux and Lima on macOS only.
Keep Python management in `uv`: `.python-version` selects the interpreter and `uv.lock` locks Python dependencies.
The setup task runs `uv sync --group test --frozen`, then `prek install`.
Tasks do not auto-install missing tools; run `mise install` explicitly before task execution.
Support Linux `x86_64`/`aarch64` and Apple Silicon macOS with prebuilt tool binaries.
Intel macOS is outside the current support scope; no Rust toolchain or Cargo fallback is required.

Complete and check tool locking with `mise lock` and `mise lock --check` after changing pins.
The initial lockfile lacks Node download metadata because the local corporate proxy blocks `nodejs.org`;
complete that entry on an approved network before requiring `mise install --locked`.

No built image, QEMU or Lima guest is needed for helper regressions.
Install the [host build/test dependencies](building.md#prerequisites) only when running image workflows.
Full hook runs include KIWI description validation, which requires Java/Jing; CI installs `jing`.

## Daily Workflow

1. Create a branch.
2. Make focused changes and add helper regressions for error paths before using privileged builds or guests.
3. Run `mise run check-all`, then run hooks and review formatting changes.
4. Build and boot an image when changing image contents, assembly or guest runtime behavior.
5. Report helper tests, builds and guest boots separately in the pull request;
   VM tests do not validate physical hardware.

## Local Validation Commands

```bash
mise run check-all
mise run lint
```

Run `check-all` to execute Python, Node artifact and workflow suites in sequence, stopping on a failure.
Run `mise run lint` for `prek run --all-files`, using `.pre-commit-config.yaml`.
Keep hooks separate from helper regressions: they may initialize isolated environments,
validate KIWI descriptions and apply formatting fixes; review the diff.
Run mise-managed tool hooks as system hooks through `mise exec` to share `mise.toml`/`mise.lock` pins without duplicate
hook-local tool installs.
Run the KIWI system hook through `mise run check-kiwi` to share the `uv.lock`-pinned build dependency group.
This task validates both architecture profiles and may synchronize `.venv`; Java/Jing remains a host prerequisite.
Run Ansible lint through `mise run lint-ansible` using the frozen uv `lint` dependency group.
Keep this task check-only by default; pass `--fix` to apply changes.
The manual `ansible-lint` hook retains `--fix` and scans the whole repository, even when no files match.
Both invocations use the same `uv.lock`-pinned version and may synchronize `.venv`.
Keep the current stages explicit:

| Source             | Active commit checks                               | Manual checks and promotion condition                                                        |
| ------------------ | -------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Text and source    | `typos` spelling (check-only)                      | None                                                                                         |
| Shell              | Shuck lint                                         | `shuck-format`: format existing scripts                                                      |
| GitHub Actions     | jactionlint correctness; Shuck embedded-shell lint | `zizmor`: resolve security findings                                                          |
| TOML               | Tombi lint                                         | `tombi-format`: format existing TOML                                                         |
| YAML and KIWI YAML | YAML parsing; uv-managed KIWI validation           | `ryl`, `ryl-format`: reconcile document markers, indentation, merge overrides and formatting |
| Markdown           | Generic whitespace and smartquote hooks            | `rumdl`: reconcile tables and semantic line breaks                                           |
| Python             | Generic integrity hooks                            | `ruff`, `ruff-format`: resolve strict-rule and formatting debt                               |
| Ansible            | Shared YAML checks                                 | uv-managed `ansible-lint` manual hook                                                        |
| JavaScript         | Node artifact regression tests                     | No dedicated linter/formatter in this migration                                              |

Run a quarantined check with `mise exec -- prek run <hook-id> --all-files --hook-stage manual`.
Use the hook IDs in the table; for example:

```bash
mise exec -- prek run ryl --all-files --hook-stage manual
mise exec -- prek run rumdl --all-files --hook-stage manual
mise exec -- prek run zizmor --all-files --hook-stage manual
```

Run formatting checks without writes during adoption.
Remove a hook's `stages: [manual]` only after its full tracked-file run passes
and the resulting policy/formatting changes have been reviewed.
Configure Ruff through `pyproject.toml` and `.config/ruff.toml`; retain the supplied `.config/ryl.toml`,
`.config/rumdl.toml` and `.config/tombi.toml` policies.
Include `*.kiwi` in ryl's YAML globs.
Run spelling checks with `mise exec -- prek run typos --all-files`.
Use `.config/typos.toml` for narrow spelling exceptions and generated lockfile/image exclusions;
run the CLI with `mise exec -- typos --config .config/typos.toml --force-exclude <paths>` without auto-fix flags.
Shuck replaces ShellCheck for standalone and workflow shell; jactionlint uses Ruff for embedded Python.
Use `.github/jactionlint.yaml` to keep its correctness profile aligned with the previous actionlint gate.
Use these tasks for narrower feedback:

| Task                       | Scope                                                    |
| -------------------------- | -------------------------------------------------------- |
| `mise run check`           | Python helper regressions in `tests/`                    |
| `mise run check-artifacts` | Node artifact-cleanup and artifact-selection regressions |
| `mise run check-workflows` | Python workflow helper regressions                       |
| `mise run check-kiwi`      | KIWI descriptions for both architecture profiles         |
| `mise run lint-ansible`    | Repository-wide Ansible lint without fixes               |

For direct Python execution, run `uv run --group test --frozen python -m unittest discover -s tests -p 'test_*.py'`.
The runner is stdlib `unittest`, but schema checks require Molecule from the test group even without a VM.
These helper checks do not build or boot an image.

## Documentation Site

Use [Zensical](https://zensical.org/) to render the existing `docs/` Markdown without maintaining separate site content.
Keep documentation dependencies in the `docs` group, separate from image-build and test dependencies.
Run from the repository root:

```bash
mise run docs-build
mise run docs-serve
```

Build with the frozen `uv.lock` into ignored `site/`; `docs-build` fails on Zensical warnings.
Preview at <http://127.0.0.1:8000>; stop the preview with Ctrl+C.
Both tasks sync the docs dependency group automatically; `mise run setup` remains unchanged.
Configure site metadata and navigation in `zensical.toml`; retain `docs/README.md` as the homepage.
Keep relative links between documentation pages and use GitHub URLs for files outside `docs/`.
Use the separate [documentation workflow](github-actions.md#documentation-publishing) to check pull requests
and publish `trunk` to GitHub Pages.
Set `project.site_url` to `https://digitalr00ts.github.io/kickstart/` for the project-site base path.
Enable GitHub Actions as the Pages source before the first deployment.

## Host Prerequisite Diagnostics

Run the read-only doctor before image work:

```bash
mise run doctor
mise run doctor --scope build
mise run doctor --scope test
```

Use the default `all` scope to check both build and test prerequisites.
Fix reported failures, then rerun the doctor.
The checker reports supported OS/CPU, executable availability, macOS checkout/image path constraints,
EFI firmware lookup, valid acceleration selection and Linux KVM permissions.
On macOS, the test scope queries QEMU's accelerator list with a bounded `-accel help` command; it does not boot a guest.
No built image is required.

The doctor does not install packages, invoke sudo, start Lima, run guest commands or change image/runtime files.
The doctor task uses `uv run --no-project`, avoiding project dependency synchronization.
Other tasks using `uv run --frozen` can still synchronize the Python environment. uv can acquire the interpreter
selected by `.python-version` if it is not already available.
Keep the Python 3.15 pin aligned with `pyproject.toml`;
the lockfile uses Ansible Core 2.22 for controller compatibility.
Passing diagnostics does not prove complete KIWI system dependencies, matching firmware contents, Lima guest readiness,
usable acceleration or a successful build/boot.
Follow the build/test guides for runtime proof.

## Image Validation

For a full native build and VM test pass:

```bash
mise run build
mise run test
```

For explicit Molecule lifecycle commands,
use `uv run --group test --frozen molecule test -s qemu` and `uv run --group test --frozen molecule destroy -s qemu`.
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
- keep base verification non-repairing and collection compatibility separate;
  use the [proposed collection acceptance criteria](testing.md#proposed-collection-compatibility-stage-not-implemented)
- review optional KIWI `*.packages` manifests when changing image packages; justify growth against the base purpose
