## Context

This project establishes an automated build system for Fedora images targeting development and testing environments. Currently, there is no repeatable process for creating standardized Fedora images across QEMU and VirtualBox platforms. Manual image creation leads to configuration drift and makes it difficult to test infrastructure code consistently.

The system must support:
- Fedora 43 initially, with structure for future versions
- Two variants: minimal server and workstation (with GUI)
- Two virtualization platforms: QEMU (for libvirt/KVM) and VirtualBox
- Local development workflow with the drts01 Ansible collection
- Production builds using the GitHub-hosted collection

Current environment:
- Packer 1.15.0 installed
- QEMU 10.1.4 installed
- VirtualBox and Ansible recently installed
- Empty repository with OpenSpec workflow structure

## Goals / Non-Goals

**Goals:**
- Automated, repeatable image builds with zero manual intervention
- Minimal base configuration via kickstart (network, auth, packages only)
- Ansible-driven post-installation configuration
- Fast development cycle for testing Ansible collection changes
- Support both QEMU and VirtualBox with feature parity
- Comprehensive testing to validate images before use
- Version-aware structure extensible to future Fedora releases
- Optional Vagrant box generation for development environments

**Non-Goals:**
- Cloud provider images (AWS, Azure, GCP) - focus is local virtualization only
- Production-ready hardening - these are development/testing images
- GUI testing automation for workstation variant
- Multi-architecture support (ARM, etc.) - x86_64 only initially
- Image distribution/hosting infrastructure
- Custom kernel builds or package repositories

## Decisions

### D1: Packer as Build Orchestrator
**Decision:** Use HashiCorp Packer as the primary build tool.

**Rationale:** 
- Industry standard for image building with strong community
- Native support for QEMU and VirtualBox builders
- Built-in provisioner support for Ansible
- Declarative HCL configuration enables version control
- Post-processor support for Vagrant box creation

**Alternatives Considered:**
- Ansible alone: Lacks native ISO-to-image workflow, would require custom scripting
- libvirt-install + scripts: Too platform-specific, harder to maintain
- Manual builds: Error-prone, not repeatable

### D2: Minimal Kickstart Philosophy
**Decision:** Keep kickstart files minimal with only essential installation configuration.

**Rationale:**
- Clear separation of concerns: kickstart for installation, Ansible for configuration
- Easier to maintain and understand
- Enables reuse of kickstart base across variants
- Post-installation changes via Ansible are easier to test and iterate

**Configuration Split:**
- Kickstart: language, keyboard, timezone, network, authentication, bootloader, disk partitioning, base packages
- Ansible: user management, services, security hardening, application installation

### D3: Dual-Source Ansible Collection Support
**Decision:** Support both local filesystem and GitHub as Ansible collection sources.

**Rationale:**
- Local source enables fast development iteration without git commits
- GitHub source ensures production builds use versioned, reviewed code
- Developers can test collection changes by rebuilding images with local collections
- Environment variable (`ANSIBLE_COLLECTIONS_PATH`) provides clean switching mechanism

**Implementation:**
- `ansible.cfg` defines default collections path
- Packer provisioner accepts `ansible_env_vars` to override
- `requirements.yml` used only for GitHub-based builds

### D4: Modular Packer Template Structure
**Decision:** Split Packer configuration into separate HCL files: variables, sources, build.

**Rationale:**
- Variables.pkr.hcl: Reusable variable definitions
- Sources.pkr.hcl: Builder-specific configurations (QEMU, VirtualBox)
- Build.pkr.hcl: Provisioning and post-processing logic
- Version-specific files (fedora-43.pkrvars.hcl): ISO URLs and checksums

**Benefits:**
- Adding new Fedora versions only requires new .pkrvars.hcl file
- Adding new builders only requires extending sources.pkr.hcl
- Provisioning logic shared across all builds
- Easier to review and maintain

### D5: Separate Testing Script per Platform
**Decision:** Create platform-specific test scripts (test-qemu.sh, test-virtualbox.sh) with shared validation library.

**Rationale:**
- VM lifecycle management differs between QEMU and VirtualBox
- Platform-specific features need different validation approaches
- Shared validation.sh provides common test functions
- Enables running platform tests independently

### D6: Makefile for Build Automation
**Decision:** Use GNU Make as the build automation interface.

**Rationale:**
- Simple, ubiquitous, and well-understood
- Clear targets for each build variant (build-server-qemu, build-workstation-virtualbox)
- Dependency management for prerequisites (packer init, validation)
- Easy to extend for CI/CD integration

**Alternatives Considered:**
- Bash scripts: Less structured, harder to see dependencies
- Task runners (just, cargo-make): Adds external dependency
- CI/CD only: Limits local developer workflow

### D7: Incremental Ansible Testing Workflow
**Decision:** Enable testing Ansible changes without full Packer rebuild.

**Rationale:**
- Full Packer build takes significant time (ISO download, installation, provisioning)
- Ansible collection development requires rapid iteration
- Running ansible-playbook directly against running VM is much faster

**Implementation:**
- Document workflow for booting existing image manually
- Provide script to apply playbook to running VM with local collection
- Support ansible --check mode for dry runs
- Include test script specifically for collection validation

## Risks / Trade-offs

**[R1] Kickstart Syntax Changes Across Fedora Versions**
→ Mitigation: Version-specific kickstart files in http/<version>/ directory structure if needed. Start with single base + variants for F43.

**[R2] ISO Download Failures During Build**
→ Mitigation: Document multiple ISO mirror URLs. Packer caches ISOs in ~/.packer.d/cache. Consider pre-downloading ISOs for offline builds.

**[R3] Build Time for Full Image (30-60 minutes)**
→ Mitigation: Incremental Ansible testing workflow bypasses full rebuild. Consider creating base images without Ansible for development.

**[R4] VirtualBox and QEMU Feature Parity**
→ Mitigation: Shared kickstart and Ansible ensure identical configuration. Platform-specific settings isolated to Packer sources. Test both platforms regularly.

**[R5] Local Ansible Collection Path Conflicts**
→ Mitigation: Clear documentation on ANSIBLE_COLLECTIONS_PATH precedence. Recommend using explicit paths, not relative. Provide make targets that set environment correctly.

**[R6] Disk Space Requirements (Multiple Variants)**
→ Trade-off: Each build produces ~2-4GB artifacts. QEMU qcow2 format provides sparse files. Document cleanup procedures and output directory structure.

**[R7] SSH Access for Testing Requires Temporary Credentials**
→ Trade-off: Kickstart creates root user with known password "packer" for provisioning. Ansible should disable/remove this or create proper users. Document security implications.

**[R8] Workstation Variant Boot Time and Resource Usage**
→ Trade-off: GUI environments require more memory (4GB+ recommended vs 2GB for server). Document minimum requirements per variant.

## Migration Plan

Not applicable - this is a new build system with no existing infrastructure to migrate from.

**Initial Setup:**
1. Clone repository
2. Ensure system dependencies installed (Packer, QEMU, VirtualBox, Ansible)
3. Run `packer init packer/` to install plugins
4. Run `make build-server-qemu` for initial test build
5. Verify output image boots successfully

**Rollout Strategy:**
- Start with server variant on QEMU (most stable, fastest)
- Add VirtualBox support once QEMU validated
- Add workstation variant last (most complex)
- Document any issues in docs/troubleshooting.md

## Open Questions

**Q1: Fedora 43 ISO Availability**
- Need to confirm official ISO URLs and checksums for Fedora 43 Server and Workstation
- Mirror selection strategy (primary mirror vs CDN vs multiple mirrors)

**Q2: VirtualBox Guest Additions**
- Should these be installed during build or left to users?
- Same question for QEMU guest agent
- Decision impacts image size and functionality

**Q3: Vagrant Box Naming and Versioning**
- Naming convention for Vagrant boxes (digitalroots/fedora-43-server?)
- Version numbering strategy (date-based, semantic versioning?)
- Where to document box metadata

**Q4: Collection Namespace Structure**
- What is the namespace structure of drts01 collection?
- Format: ansible_collections/<namespace>/<collection_name>/
- Need to verify for ANSIBLE_COLLECTIONS_PATH configuration

**Q5: Test Coverage Threshold**
- What level of testing is sufficient before considering an image "valid"?
- Boot + SSH + package manager, or more comprehensive?
- Performance benchmarks (boot time, memory usage)?
