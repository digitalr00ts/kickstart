# Documentation Hub

Build and test a minimal Fedora base on native Linux or macOS hosts: boot, networking and Ansible prerequisites
plus a secure baseline. Keep applications, machine roles and site-specific configuration in
[`drts.casc`](https://github.com/drts01/ansible-collection).
Distinguish VM validation from deployment: access provisioning, cloud-init and a physical installer are not implemented.

## Operators

Use this path if you need to build, validate, and troubleshoot images.

1. [Building Guide](building.md)
2. [Testing Guide](testing.md)
3. [Troubleshooting Guide](troubleshooting.md)

## Contributors

Use this path if you are changing code, scripts, or automation. Start without a VM:

```bash
uv sync --group test --frozen
uv run --frozen poe check-all
```

Install `uv` and Node.js first. `check-all` runs Python, Node artifact and workflow tests, not hooks;
`uv run --frozen poe check` remains Python-only. Follow the Development Guide for aggregate and hook details.

1. [Development Guide](development.md)
2. [Testing Guide](testing.md)
3. [CI and Automation](github-actions.md)

## Quick Navigation

- Base ownership and contributor/operator quickstarts: [Project README](../README.md)
- Build outputs and collection handoff: [Building Guide](building.md#handoff-to-drtscasc)
- Proposed collection compatibility acceptance criteria (not implemented):
  [Testing Guide](testing.md#proposed-collection-compatibility-stage-not-implemented)
- Local quality checks: [Development Guide](development.md)
- Non-repairing base validation and runtime evidence: [Testing Guide](testing.md)
- Read-only host prerequisites: `uv run --frozen poe doctor [--scope build|test|all]` (default `all`);
  no tool installation or guest launch/start, and no runtime proof
- CI pipeline layout: [CI and Automation](github-actions.md)
- Common failure recovery: [Troubleshooting Guide](troubleshooting.md)
