## ADDED Requirements

### Requirement: Provide common validation functions
The system SHALL provide a shared library of validation functions usable by all platform-specific tests.

#### Scenario: Validation library is sourceable
- **WHEN** test scripts source tests/validation.sh
- **THEN** common validation functions are available

#### Scenario: Boot validation function
- **WHEN** check_boot function is called
- **THEN** it verifies VM successfully boots and reaches login prompt

#### Scenario: SSH connectivity validation
- **WHEN** check_ssh function is called
- **THEN** it verifies SSH access to VM is functional

#### Scenario: Package installation validation
- **WHEN** check_packages function is called with package list
- **THEN** it verifies specified packages are installed

### Requirement: Test QEMU images
The system SHALL provide automated testing for QEMU-built images.

#### Scenario: QEMU test script launches VM
- **WHEN** tests/test-qemu.sh is executed with image path
- **THEN** VM is launched using qemu-system-x86_64

#### Scenario: QEMU test waits for boot
- **WHEN** QEMU VM is started
- **THEN** test script waits for SSH to become available

#### Scenario: QEMU test validates image format
- **WHEN** QEMU tests run
- **THEN** image format is verified as qcow2

### Requirement: Test VirtualBox images
The system SHALL provide automated testing for VirtualBox-built images.

#### Scenario: VirtualBox test script imports image
- **WHEN** tests/test-virtualbox.sh is executed with image path
- **THEN** image is imported into VirtualBox using VBoxManage

#### Scenario: VirtualBox test starts VM
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
- **WHEN** test script completes
- **THEN** report shows which checks passed and which failed

#### Scenario: Test report includes VM details
- **WHEN** test report is generated
- **THEN** it includes platform, variant, and build timestamp

### Requirement: Support graceful VM cleanup
The system SHALL cleanly shutdown test VMs after validation.

#### Scenario: QEMU VM shutdown
- **WHEN** QEMU tests complete
- **THEN** VM is shutdown gracefully via ACPI

#### Scenario: VirtualBox VM shutdown and cleanup
- **WHEN** VirtualBox tests complete
- **THEN** VM is stopped and unregistered from VirtualBox

### Requirement: Provide Ansible collection testing workflow
The system SHALL enable testing Ansible collection changes without full image rebuild.

#### Scenario: Test script spins up existing image
- **WHEN** tests/test-ansible-collection.sh runs
- **THEN** existing image is booted without rebuild

#### Scenario: Test script applies playbook with local collection
- **WHEN** collection test runs
- **THEN** ansible-playbook executes with ANSIBLE_COLLECTIONS_PATH set to local collection

#### Scenario: Test script compares local vs GitHub results
- **WHEN** collection test completes
- **THEN** report shows differences between local collection and GitHub version results
