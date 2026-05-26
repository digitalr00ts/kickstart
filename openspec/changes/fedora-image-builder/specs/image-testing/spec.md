## ADDED Requirements

### Requirement: Provide Molecule verification tasks
The system SHALL provide shared Molecule verify tasks usable by all platform-specific scenarios.

#### Scenario: Shared verify tasks are included
- **WHEN** Molecule verify executes for a platform scenario
- **THEN** shared verification tasks are included and run on the test instance

#### Scenario: Boot validation task
- **WHEN** verify boot task runs
- **THEN** it verifies VM successfully boots and reaches command execution

#### Scenario: SSH connectivity validation task
- **WHEN** verify SSH task runs
- **THEN** it verifies SSH access to VM is functional

#### Scenario: Package installation validation task
- **WHEN** verify package assertion task runs with variant-specific package list
- **THEN** it verifies specified packages are installed

### Requirement: Test QEMU images
The system SHALL provide automated testing for QEMU-built images.

#### Scenario: QEMU Molecule create launches VM
- **WHEN** molecule scenario `qemu-server` or `qemu-workstation` runs create
- **THEN** VM is launched using the host-selected qemu-system binary

#### Scenario: QEMU scenario waits for boot
- **WHEN** QEMU VM is started
- **THEN** Molecule converge or verify waits for SSH availability

#### Scenario: QEMU test validates image format
- **WHEN** QEMU tests run
- **THEN** image format is verified as qcow2

### Requirement: Test VirtualBox images
The system SHALL provide automated testing for VirtualBox-built images.

#### Scenario: VirtualBox Molecule create imports image
- **WHEN** molecule scenario `virtualbox-server` or `virtualbox-workstation` runs create
- **THEN** image is imported into VirtualBox using VBoxManage

#### Scenario: VirtualBox Molecule create starts VM
- **WHEN** VirtualBox image is imported
- **THEN** VM is started using VBoxManage startvm

#### Scenario: VirtualBox test verifies guest OS type
- **WHEN** VirtualBox tests run
- **THEN** VM configuration shows correct guest OS type

### Requirement: Validate core functionality
The system SHALL verify that built images have functional core capabilities.

#### Scenario: Network connectivity check
- **WHEN** image validation runs
- **THEN** VM has working network interface with IP address

#### Scenario: DNS resolution check
- **WHEN** network validation runs
- **THEN** VM can resolve external hostnames

#### Scenario: Package manager check
- **WHEN** package validation runs
- **THEN** dnf command is functional

### Requirement: Validate Ansible provisioning results
The system SHALL verify that Ansible provisioning completed successfully.

#### Scenario: Ansible-managed configuration present
- **WHEN** provisioning validation runs
- **THEN** files/services managed by Ansible are in expected state

### Requirement: Generate test reports
The system SHALL produce test result reports for each validation run.

#### Scenario: Test report includes pass/fail status
- **WHEN** Molecule scenario completes
- **THEN** report shows which checks passed and which failed

#### Scenario: Test report includes VM details
- **WHEN** test report is generated
- **THEN** it includes platform, variant, and build timestamp

### Requirement: Support graceful VM cleanup
The system SHALL cleanly shutdown test VMs after validation.

#### Scenario: QEMU VM shutdown
- **WHEN** QEMU scenario destroy runs
- **THEN** VM is shutdown and cleanup steps remove runtime PID artifacts

#### Scenario: VirtualBox VM shutdown and cleanup
- **WHEN** VirtualBox scenario destroy runs
- **THEN** VM is stopped and unregistered from VirtualBox

### Requirement: Provide Ansible collection testing workflow
The system SHALL enable testing Ansible collection changes without full image rebuild.

#### Scenario: Test script spins up existing image
- **WHEN** scripts/task.sh test ansible-collection runs
- **THEN** existing image is booted without rebuild

#### Scenario: Test script applies playbook with local collection
- **WHEN** collection test runs
- **THEN** ansible-playbook executes with ANSIBLE_COLLECTIONS_PATH set to local collection

#### Scenario: Test script compares local vs GitHub results
- **WHEN** collection test completes
- **THEN** report shows differences between local collection and GitHub version results
