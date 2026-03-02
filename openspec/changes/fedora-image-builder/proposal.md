## Why

There is currently no automated infrastructure for building and testing Fedora workstation and server images across multiple virtualization platforms. Manual image creation is time-consuming, error-prone, and difficult to reproduce consistently. This change establishes a Packer-based build system that enables reproducible, tested Fedora images with automated provisioning for both QEMU and VirtualBox platforms.

## What Changes

- Minimal kickstart configurations for Fedora 43 installation (server and workstation variants)
- Packer templates supporting QEMU and VirtualBox builders
- Ansible provisioning integration using the drts01 collection (supports both local development and GitHub sources)
- Automated testing infrastructure for image validation
- Build automation via Makefile for common operations
- Optional Vagrant box post-processing for development environments
- Comprehensive documentation for building, testing, and troubleshooting
- Version-aware structure to support future Fedora releases

## Capabilities

### New Capabilities
- `kickstart-generation`: Minimal kickstart file templates for Fedora installation with base configuration (network, auth, packages)
- `packer-builds`: Multi-platform image building orchestration for QEMU and VirtualBox
- `ansible-provisioning`: Post-installation configuration using Ansible collections with dual-source support
- `image-testing`: Automated validation of built images including boot, SSH, and configuration checks
- `build-automation`: Makefile-based workflow for building and testing all variants
- `vagrant-packaging`: Optional post-processing to create Vagrant boxes from built images

### Modified Capabilities
<!-- No existing capabilities are being modified -->

## Impact

**New Components:**
- Directory structure: http/, packer/, ansible/, scripts/, tests/, docs/
- 30+ new files including kickstart configs, Packer templates, Ansible playbooks, test scripts
- Build artifacts: QEMU qcow2 images, VirtualBox images, optional Vagrant boxes

**System Dependencies:**
- Requires: Packer 1.15+, QEMU 10+, VirtualBox 7+, Ansible 2.15+
- Packer plugins: qemu, virtualbox, ansible, vagrant (auto-installed)

**External Integrations:**
- Ansible collection from https://github.com/drts01/ansible-collection
- Fedora 43 ISO downloads from official mirrors

**Development Workflow:**
- Supports local Ansible collection development with fast iteration
- Enables testing collection changes without full image rebuilds
