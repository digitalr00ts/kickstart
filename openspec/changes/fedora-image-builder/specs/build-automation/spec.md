## ADDED Requirements

### Requirement: Provide Makefile for build automation
The system SHALL provide a Makefile with targets for common build and test operations.

#### Scenario: Build server variant for QEMU
- **WHEN** user runs make build-server-qemu
- **THEN** Packer builds server variant for QEMU platform

#### Scenario: Build server variant for VirtualBox
- **WHEN** user runs make build-server-virtualbox
- **THEN** Packer builds server variant for VirtualBox platform

#### Scenario: Build workstation variant for QEMU
- **WHEN** user runs make build-workstation-qemu
- **THEN** Packer builds workstation variant for QEMU platform

#### Scenario: Build workstation variant for VirtualBox
- **WHEN** user runs make build-workstation-virtualbox
- **THEN** Packer builds workstation variant for VirtualBox platform

### Requirement: Provide build-all target
The system SHALL provide a target to build all variants and platforms.

#### Scenario: Build all combinations
- **WHEN** user runs make build-all
- **THEN** all four combinations (server/workstation × QEMU/VirtualBox) are built

### Requirement: Provide initialization target
The system SHALL provide a target to initialize Packer plugins.

#### Scenario: Install required plugins
- **WHEN** user runs make init
- **THEN** packer init is executed to install required plugins

### Requirement: Provide validation target
The system SHALL provide a target to validate Packer templates.

#### Scenario: Validate template syntax
- **WHEN** user runs make validate
- **THEN** packer validate is executed to check template syntax

### Requirement: Provide testing targets
The system SHALL provide targets for running image tests.

#### Scenario: Test QEMU images
- **WHEN** user runs make test-qemu
- **THEN** QEMU test scripts are executed for all QEMU-built images

#### Scenario: Test VirtualBox images
- **WHEN** user runs make test-virtualbox
- **THEN** VirtualBox test scripts are executed for all VirtualBox-built images

#### Scenario: Test all images
- **WHEN** user runs make test-all
- **THEN** all test scripts are executed for all platforms

### Requirement: Provide cleanup target
The system SHALL provide a target to remove build artifacts.

#### Scenario: Clean output directory
- **WHEN** user runs make clean
- **THEN** output directory and build artifacts are removed

#### Scenario: Clean Packer cache
- **WHEN** user runs make clean
- **THEN** Packer cache directory is cleaned

### Requirement: Support environment variable overrides
The system SHALL allow users to override build parameters via environment variables.

#### Scenario: Override Ansible collections path
- **WHEN** ANSIBLE_COLLECTIONS_PATH is set when running make
- **THEN** Packer uses the specified collection path

#### Scenario: Override variant or version
- **WHEN** build variables are set in environment
- **THEN** Makefile passes them to Packer

### Requirement: Provide help target
The system SHALL provide a help target listing available make targets.

#### Scenario: Display available targets
- **WHEN** user runs make help or make
- **THEN** list of available targets with descriptions is displayed

### Requirement: Include prerequisite checks
The system SHALL verify required tools are installed before building.

#### Scenario: Check for Packer
- **WHEN** build target is invoked
- **THEN** Makefile verifies packer command is available

#### Scenario: Check for QEMU or VirtualBox
- **WHEN** platform-specific build is invoked
- **THEN** Makefile verifies required virtualization tool is installed
