## ADDED Requirements

### Requirement: Support local Ansible collection during development
The system SHALL allow using a local filesystem path to the Ansible collection for rapid development iteration.

#### Scenario: Local collection path via environment variable
- **WHEN** ANSIBLE_COLLECTIONS_PATH environment variable is set
- **THEN** Packer uses the local collection instead of downloading from GitHub

#### Scenario: Local collection path in ansible.cfg
- **WHEN** ansible.cfg defines collections_path
- **THEN** Ansible searches specified directories for collections

### Requirement: Support GitHub-sourced Ansible collection for production
The system SHALL support installing the Ansible collection from GitHub for production builds.

#### Scenario: GitHub collection via requirements.yml
- **WHEN** ansible/requirements.yml specifies the drts01 collection from GitHub
- **THEN** Packer downloads and installs the collection during provisioning

#### Scenario: GitHub collection uses specific version
- **WHEN** requirements.yml specifies version "trunk"
- **THEN** the latest trunk branch is used

### Requirement: Provide separate playbooks for variants
The system SHALL provide variant-specific Ansible playbooks for server and workstation configurations.

#### Scenario: Server playbook for minimal configuration
- **WHEN** building server variant
- **THEN** playbook-server.yml is executed with server-appropriate roles

#### Scenario: Workstation playbook for desktop configuration
- **WHEN** building workstation variant
- **THEN** playbook-workstation.yml is executed with desktop-appropriate roles

### Requirement: Pass build context to Ansible
The system SHALL pass relevant build information to Ansible playbooks as extra variables.

#### Scenario: Fedora version passed to playbooks
- **WHEN** Packer provisions with Ansible
- **THEN** fedora_version variable is available in playbooks

### Requirement: Prepare system for Ansible execution
The system SHALL ensure Python and dependencies are installed before running Ansible playbooks.

#### Scenario: Python 3 installed via shell provisioner
- **WHEN** Packer reaches Ansible provisioning stage
- **THEN** Python 3 and pip are installed via dnf

#### Scenario: Python alternative configured
- **WHEN** Python installation completes
- **THEN** /usr/bin/python3 is set as the default python alternative

### Requirement: Install Ansible collections during provisioning
The system SHALL configure Packer Ansible provisioner to install required collections.

#### Scenario: Galaxy file specifies collection requirements
- **WHEN** Packer Ansible provisioner runs
- **THEN** galaxy_file points to ansible/requirements.yml

#### Scenario: Collections installed before playbook execution
- **WHEN** Ansible provisioner starts
- **THEN** collections are installed from requirements.yml before running playbooks

### Requirement: Support Ansible configuration file
The system SHALL provide ansible.cfg for Packer provisioning runs.

#### Scenario: Ansible configuration controls behavior
- **WHEN** Packer runs Ansible provisioner
- **THEN** ansible/ansible.cfg is used for Ansible settings

### Requirement: Enable testing Ansible changes without rebuilding
The system SHALL support running Ansible playbooks directly against existing VMs for rapid iteration.

#### Scenario: Standalone playbook execution
- **WHEN** user runs ansible-playbook directly with VM IP
- **THEN** playbook executes against running VM without Packer

#### Scenario: Local collection in standalone execution
- **WHEN** ansible-playbook is run with custom collections_path
- **THEN** local collection is used instead of installed version
