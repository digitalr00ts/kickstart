# CI and Automation

This document outlines a practical CI layout for this repository.

## Suggested Pipeline Stages

1. Lint and static checks
2. Collection and playbook validation
3. Scenario validation

## Stage 1: Lint

```bash
pre-commit run --all-files
```

## Stage 2: Collection and Playbook Checks

```bash
uv run poe test ansible-collection
```

## Stage 3: Scenario Validation

```bash
uv run poe test qemu
```

## Optional Build Artifact Stage

For release workflows, produce image artifacts:

```bash
uv run poe build-kiwi
uv run poe status
```

## Caching Tips

- cache Python dependencies used by `uv`
- cache downloaded collection content when suitable
- avoid caching generated image artifacts unless release jobs require it

## Failure Triage Order

1. Read pre-commit output first.
2. Check collection validation output.
3. Check scenario create/converge/verify logs.
4. Reproduce locally with the same command sequence.
