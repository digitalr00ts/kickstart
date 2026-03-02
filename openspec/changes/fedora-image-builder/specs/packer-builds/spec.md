## ADDED Requirements

### Requirement: Support QEMU builder
The system SHALL provide Packer configuration for building images using the QEMU builder targeting KVM/libvirt environments.

#### Scenario: QEMU builder creates qcow2 images
- **WHEN** QEMU build completes
- **THEN** output is in qcow2 format suitable for libvirt/KVM

#### Scenario: QEMU builder uses KVM acceleration
- **WHEN** QEMU builder is configured
- **THEN** accelerator is set to "kvm" for optimal performance

### Requirement: Support VirtualBox builder
The system SHALL provide Packer configuration for building images using the VirtualBox-ISO builder.

#### Scenario: VirtualBox builder creates OVF/OVA images
- **WHEN** VirtualBox build completes
- **THEN** output includes VirtualBox-compatible disk and configuration files

#### Scenario: VirtualBox builder uses correct guest OS type
- **WHEN** VirtualBox builder is configured
- **THEN** guest_os_type is set to "Fedora_64"

### Requirement: Define modular template structure
The system SHALL organize Packer templates into separate HCL files for maintainability.

#### Scenario: Variables defined in dedicated file
- **WHEN** Packer templates are loaded
- **THEN** variables.pkr.hcl contains all variable definitions

#### Scenario: Sources defined separately from build logic
- **WHEN** Packer templates are loaded
- **THEN** sources.pkr.hcl contains builder source blocks independently from build blocks

#### Scenario: Version-specific values in separate files
- **WHEN** building for Fedora 43
- **THEN** fedora-43.pkrvars.hcl provides ISO URLs and checksums

### Requirement: Support variant selection
The system SHALL allow building different variants (server, workstation) from the same template.

#### Scenario: Variant determines kickstart file
- **WHEN** variant variable is set to "server"
- **THEN** build uses ks-server.cfg

#### Scenario: Variant determines output directory
- **WHEN** variant variable is set to "workstation"
- **THEN** output is written to output/qemu-workstation/ or output/virtualbox-workstation/

### Requirement: Configure hardware specifications
The system SHALL define configurable hardware specifications for virtual machines.

#### Scenario: Default memory allocation
- **WHEN** no memory override is provided
- **THEN** VMs are allocated 2048MB RAM by default

#### Scenario: Default disk size
- **WHEN** no disk_size override is provided
- **THEN** VMs have 40GB disk space

#### Scenario: CPU core allocation
- **WHEN** no cpus override is provided
- **THEN** VMs are allocated 2 CPU cores

### Requirement: Enable SSH access for provisioning
The system SHALL configure Packer builders to access VMs via SSH for provisioning.

#### Scenario: SSH credentials match kickstart
- **WHEN** Packer connects to VM
- **THEN** ssh_username is "root" and ssh_password is "packer"

#### Scenario: SSH timeout allows for installation
- **WHEN** Packer waits for SSH
- **THEN** timeout is at least 30 minutes to allow for ISO download and installation

### Requirement: Install Packer plugins automatically
The system SHALL define required Packer plugins that are installed via packer init.

#### Scenario: Required plugins are declared
- **WHEN** packer init is run
- **THEN** qemu, virtualbox, ansible, and vagrant plugins are installed

#### Scenario: Plugin versions are specified
- **WHEN** plugin declarations are reviewed
- **THEN** minimum version constraints are defined (e.g., ">= 1.1.0")

### Requirement: Validate templates before building
The system SHALL support validation of Packer templates without executing builds.

#### Scenario: Validation catches syntax errors
- **WHEN** packer validate is run
- **THEN** HCL syntax errors are reported before build execution
