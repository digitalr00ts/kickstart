# Development Guide

This guide covers development workflows, tools, and best practices for contributing to the Fedora Image Builder project.

## Pre-commit Hooks

This project uses [pre-commit](https://pre-commit.com/) to ensure code quality and catch issues before they're committed.

### Installation

```bash
# Install pre-commit
pip install pre-commit

# Install the git hooks
pre-commit install

# (Optional) Install commit-msg hook
pre-commit install --hook-type commit-msg
```

### What Gets Checked

The pre-commit hooks validate:

#### 1. **Kickstart Files** (`http/*.cfg`)

- Syntax validation with `ksvalidator` (if available)
- Trailing whitespace
- File endings

#### 2. **Packer Templates** (`packer/*.pkr.hcl`)

- Format checking (`packer fmt`)
- Template validation (`packer validate`)
- Syntax correctness

#### 3. **Ansible Files** (`ansible/*.yml`)

- Ansible-lint validation
- YAML syntax
- Best practices enforcement

#### 4. **Shell Scripts** (`scripts/*.sh`, `tests/*.sh`)

- ShellCheck validation
- Executable permissions
- Shebang presence

#### 5. **General Files**

- YAML syntax validation
- Trailing whitespace removal
- End-of-file fixing
- Large file detection (10MB limit)
- Merge conflict markers
- Secret detection

#### 6. **Build Artifacts** (blocked)

- ISO files
- QCOW2 images
- VDI images
- Vagrant boxes

These should never be committed to git!

### Running Pre-commit

```bash
# Run on staged files (automatic when you commit)
git commit -m "your message"

# Run on all files manually
pre-commit run --all-files

# Run specific hook
pre-commit run packer-validate --all-files
pre-commit run shellcheck --all-files
pre-commit run ansible-lint --all-files

# Update hooks to latest versions
pre-commit autoupdate
```

### Fixing Issues

Many hooks auto-fix issues:

- `trailing-whitespace` - removes trailing spaces
- `end-of-file-fixer` - ensures files end with newline
- `packer fmt` - formats Packer templates
- `markdownlint --fix` - fixes markdown issues
- `ansible-lint --write` - fixes Ansible issues

After auto-fixes, review changes and re-stage:

```bash
git add .
git commit -m "your message"
```

### Bypassing Hooks (Not Recommended)

Only in emergencies:

```bash
git commit --no-verify -m "emergency fix"
```

### Installing Required Tools

Some hooks require additional tools:

```bash
# Fedora/RHEL
sudo dnf install pykickstart ShellCheck ansible-lint

# Ubuntu/Debian
sudo apt install pykickstart shellcheck ansible-lint

# Python tools via pip
pip install ansible-lint black isort detect-secrets
```

## Development Workflow

### Making Changes

1. **Create a branch**:

   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make your changes**:
   - Edit files as needed
   - Test locally

3. **Run validations**:

   ```bash
   # Run all pre-commit checks
   pre-commit run --all-files

   # Validate Packer
   make validate

   # Test Ansible
   ./tests/test-ansible-collection.sh
   ```

4. **Commit changes**:

   ```bash
   git add .
   git commit -m "descriptive message"
   # Pre-commit hooks run automatically
   ```

5. **Push and create PR**:

   ```bash
   git push origin feature/my-feature
   ```

### Testing Changes

#### Test Kickstart Changes

```bash
# Validate syntax
ksvalidator http/ks-server.cfg

# Test with a build (recommended)
make build-server-qemu
```

#### Test Packer Changes

```bash
# Validate templates
make validate

# Format check
packer fmt -check packer/

# Auto-format
packer fmt -recursive packer/

# Test build
make build-server-qemu
```

#### Test Ansible Changes

```bash
# Validate playbooks
./tests/test-ansible-collection.sh

# Lint playbooks
ansible-lint ansible/playbook-server.yml

# Test with local collection
export ANSIBLE_COLLECTIONS_PATH=/path/to/local/collection
make build-server-qemu
```

#### Test Scripts

```bash
# Check syntax
shellcheck scripts/*.sh tests/*.sh

# Make executable
chmod +x scripts/my-script.sh

# Run tests
./tests/test-qemu.sh server
```

## Code Style Guidelines

### Packer HCL

```hcl
# Use consistent formatting (automated by packer fmt)
variable "example" {
  type        = string
  description = "Description here"
  default     = "value"
}

# Comment blocks of related configuration
# This is a good comment

# Use descriptive names
provisioner "shell" {
  # ...
}
```

### Kickstart

```cfg
# Use comments to explain non-obvious choices
# Group related configuration together

# Clear sections
# Network configuration
network --bootproto=dhcp

# Disk configuration
autopart --type=lvm
```

### Ansible

```yaml
---
# Follow ansible-lint recommendations
# Use FQCN for modules (ansible.builtin.*)
# Descriptive task names

- name: Install required packages
  ansible.builtin.dnf:
    name:
      - package1
      - package2
    state: present
```

### Shell Scripts

```bash
#!/bin/bash
# Script description
# Usage: script.sh [args]

set -e  # Exit on error

# Use meaningful variable names
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function documentation
function my_function() {
    local arg=$1
    # Function body
}
```

## Troubleshooting Pre-commit

### Hook Failures

If a hook fails:

1. **Read the error message** - it usually tells you what's wrong
2. **Fix the issue** - many hooks provide suggestions
3. **Re-run** - `pre-commit run --all-files`
4. **Re-stage** - `git add .` if files were modified
5. **Commit again** - `git commit`

### Common Issues

**Packer validation fails:**

```bash
# Review the active Fedora vars file
vim packer/fedora-44.pkrvars.hcl

# Run validation manually
cd packer && packer validate -var-file=fedora-44.pkrvars.hcl .
```

**Ansible-lint fails:**

```bash
# Review specific rule
ansible-lint --list-rules

# Fix automatically where possible
ansible-lint --write ansible/playbook-server.yml
```

**ShellCheck warnings:**

```bash
# Review specific warning
shellcheck scripts/my-script.sh

# Disable specific check if needed (use sparingly)
# shellcheck disable=SC2086
```

### Skipping Specific Files

Edit `.pre-commit-config.yaml`:

```yaml
- id: some-hook
  exclude: ^path/to/exclude/
```

## CI/CD Integration

Pre-commit hooks should also run in CI:

```yaml
# .github/workflows/validate.yml
- name: Run pre-commit
  run: |
    pip install pre-commit
    pre-commit run --all-files
```

## Best Practices

1. **Run pre-commit before pushing** - catch issues early
2. **Keep hooks updated** - `pre-commit autoupdate`
3. **Don't bypass hooks** - they're there to help
4. **Test your changes** - validation passes ≠ working code
5. **Use meaningful commit messages** - describe what and why
6. **Keep commits atomic** - one logical change per commit

## Getting Help

- Pre-commit docs: <https://pre-commit.com/>
- Packer docs: <https://www.packer.io/docs>
- Ansible-lint: <https://ansible-lint.readthedocs.io/>
- ShellCheck: <https://www.shellcheck.net/>

For project-specific issues:

- Check [troubleshooting.md](troubleshooting.md)
- Open an issue on GitHub
