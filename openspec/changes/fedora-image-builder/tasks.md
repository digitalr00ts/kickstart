## 1. Project Structure and Foundation

- [x] 1.1 Create directory structure (http/, packer/, ansible/, scripts/, molecule/, docs/)
- [x] 1.2 Create .gitignore to exclude build artifacts (.packer_cache, output/, *.box, *.qcow2, *.vdi)
- [x] 1.3 Create README.md with project overview and quick start guide
- [x] 1.4 Verify system dependencies (Packer, QEMU, VirtualBox, Ansible, Make)

## 2. Kickstart Configuration Files

- [x] 2.1 Create http/ks-base.cfg with minimal base configuration (language, keyboard, timezone, network, auth, bootloader, partitioning)
- [x] 2.2 Create http/ks-server.cfg that includes base configuration plus minimal server packages
- [x] 2.3 Create http/ks-workstation.cfg that includes base configuration plus desktop packages
- [x] 2.4 Add comments documenting temporary root password and security implications
- [x] 2.5 Validate kickstart syntax if ksvalidator is available

## 3. Packer Template Structure

- [x] 3.1 Create packer/variables.pkr.hcl with all variable definitions (fedora_version, iso_url, iso_checksum, variant, output_directory, disk_size, memory, cpus)
- [x] 3.2 Create packer/sources.pkr.hcl with QEMU source block configuration
- [x] 3.3 Add required_plugins block to sources.pkr.hcl (qemu, virtualbox, ansible, vagrant)
- [x] 3.4 Create packer/fedora-43.pkrvars.hcl with Fedora 43 ISO URLs and SHA256 checksums
- [x] 3.5 Create packer/build.pkr.hcl with initial shell provisioner for Python installation
- [x] 3.6 Run packer init packer/ to install required plugins
- [x] 3.7 Run packer validate packer/ to verify template syntax

## 4. QEMU Builder Implementation

- [ ] 4.1 Configure QEMU source with hardware settings (disk_size, memory, cpus)
- [ ] 4.2 Configure QEMU SSH access (ssh_username, ssh_password, ssh_timeout)
- [ ] 4.3 Configure QEMU boot command with kickstart URL reference
- [ ] 4.4 Set QEMU accelerator to "kvm" and format to "qcow2"
- [ ] 4.5 Configure QEMU output directory using variant variable
- [ ] 4.6 Test server variant build: packer build -only=qemu.fedora -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/
- [ ] 4.7 Manually verify qcow2 image boots and SSH is accessible
- [ ] 4.8 Document any issues and adjust configuration as needed

## 5. Ansible Integration

- [ ] 5.1 Create ansible/requirements.yml with drts01 collection from GitHub
- [ ] 5.2 Create ansible/ansible.cfg with collections_path configuration
- [ ] 5.3 Create ansible/playbook-server.yml with basic server configuration tasks
- [ ] 5.4 Create ansible/playbook-workstation.yml with desktop configuration tasks
- [ ] 5.5 Add Ansible provisioner to packer/build.pkr.hcl with galaxy_file and playbook_file
- [ ] 5.6 Configure Ansible provisioner to pass fedora_version as extra variable
- [ ] 5.7 Configure Ansible provisioner with ansible_env_vars for ANSIBLE_COLLECTIONS_PATH support
- [ ] 5.8 Test build with Ansible provisioning enabled
- [ ] 5.9 Verify Ansible collection is installed and playbook executes successfully

## 6. VirtualBox Builder Implementation

- [ ] 6.1 Add VirtualBox source block to packer/sources.pkr.hcl
- [ ] 6.2 Configure VirtualBox guest_os_type as "Fedora_64"
- [ ] 6.3 Configure VirtualBox hardware (hard_drive_interface: sata, iso_interface: sata)
- [ ] 6.4 Configure VirtualBox SSH and boot settings matching QEMU configuration
- [ ] 6.5 Update packer/build.pkr.hcl to include virtualbox-iso.fedora source
- [ ] 6.6 Test server variant build: packer build -only=virtualbox-iso.fedora -var-file=packer/fedora-43.pkrvars.hcl -var variant=server packer/
- [ ] 6.7 Manually verify VirtualBox image boots and is functional
- [ ] 6.8 Compare QEMU and VirtualBox configurations for consistency

## 7. Workstation Variant Implementation

- [ ] 7.1 Verify http/ks-workstation.cfg includes GUI package groups
- [ ] 7.2 Update ansible/playbook-workstation.yml with desktop-specific roles
- [ ] 7.3 Test workstation build for QEMU platform
- [ ] 7.4 Test workstation build for VirtualBox platform
- [ ] 7.5 Verify GUI is available in workstation images (if applicable to test)

## 8. Build Automation with Makefile

- [x] 8.1 Create Makefile with .PHONY declarations
- [x] 8.2 Add make init target (runs packer init)
- [x] 8.3 Add make validate target (runs packer validate)
- [x] 8.4 Add make build-server-qemu target
- [x] 8.5 Add make build-server-virtualbox target
- [x] 8.6 Add make build-workstation-qemu target
- [x] 8.7 Add make build-workstation-virtualbox target
- [x] 8.8 Add make build-all target that builds all variants
- [x] 8.9 Add make clean target to remove output directory and artifacts
- [x] 8.10 Add make help target listing all available targets
- [x] 8.11 Add prerequisite checks for required tools (packer, qemu-system-x86_64, VBoxManage)
- [ ] 8.12 Test all Makefile targets (blocked by ISO checksums)

## 9. Utility Scripts

- [x] 9.1 Create scripts/cleanup.sh for pre-build cleanup operations
- [x] 9.2 Create scripts/prepare-output.sh to prepare output directory structure
- [x] 9.3 Create scripts/vagrant-prepare.sh for Vagrant box preparation
- [x] 9.4 Make all scripts executable (chmod +x)
- [ ] 9.5 Test cleanup script functionality (can test anytime)

## 10. Testing Infrastructure

- [x] 10.1 Create Molecule scenarios for qemu-server and qemu-workstation
- [x] 10.2 Create Molecule scenarios for virtualbox-server and virtualbox-workstation
- [x] 10.3 Implement shared Molecule create tasks for QEMU and VirtualBox lifecycle
- [x] 10.4 Implement shared Molecule verify tasks for boot, SSH, packages, services, filesystem, network, and package manager checks
- [x] 10.5 Implement shared Molecule destroy tasks for VM cleanup
- [x] 10.6 Remove standalone QEMU wrapper script
- [x] 10.7 Remove standalone VirtualBox wrapper script
- [x] 10.8 Route scripts/task.sh test commands to Molecule scenarios
- [x] 10.9 Retire legacy shell validation path
- [x] 10.10 Add task runner ansible-collection test command path
- [x] 10.11 Add task runner test-qemu command path
- [x] 10.12 Add task runner test-virtualbox command path
- [x] 10.13 Add task runner test-all command path
- [x] 10.14 Make all test scripts executable
- [ ] 10.15 Run tests against existing builds to validate test scripts (blocked by ISO checksums)

## 11. Vagrant Post-Processor (Optional)

- [ ] 11.1 Add Vagrant post-processor block to packer/build.pkr.hcl
- [ ] 11.2 Configure Vagrant post-processor for libvirt provider (QEMU builds)
- [ ] 11.3 Configure Vagrant post-processor for virtualbox provider
- [ ] 11.4 Update scripts/vagrant-prepare.sh with Vagrant user creation
- [ ] 11.5 Test Vagrant box creation for QEMU
- [ ] 11.6 Test Vagrant box creation for VirtualBox
- [ ] 11.7 Test vagrant box add with created boxes
- [ ] 11.8 Test vagrant up with added boxes
- [ ] 11.9 Verify vagrant ssh access works

## 12. Documentation

- [x] 12.1 Create docs/kickstart-reference.md documenting kickstart configuration choices
- [x] 12.2 Create docs/building.md with detailed build instructions and examples
- [x] 12.3 Create docs/testing.md with testing procedures and validation steps
- [x] 12.4 Create docs/troubleshooting.md with common issues and solutions
- [x] 12.5 Document Ansible collection testing workflow in docs/testing.md
- [x] 12.6 Document local vs GitHub collection usage in docs/building.md
- [x] 12.7 Update README.md with complete usage examples
- [x] 12.8 Add quick start guide to README.md
- [x] 12.9 Document system requirements in README.md
- [x] 12.10 Add example commands for each build variant to README.md

## 13. Final Validation and Polish

- [ ] 13.1 Run make clean to start fresh
- [ ] 13.2 Run make init to ensure plugins are installed
- [ ] 13.3 Run make validate to check all templates
- [ ] 13.4 Run make build-all to build all variants and platforms
- [ ] 13.5 Run make test-all to validate all built images
- [ ] 13.6 Verify disk space usage is reasonable
- [ ] 13.7 Document actual build times for each variant
- [ ] 13.8 Test with local Ansible collection path
- [ ] 13.9 Test with GitHub Ansible collection
- [ ] 13.10 Create git tag for initial release
- [ ] 13.11 Update implementation_plan.md with any lessons learned
