# Packer Build Configuration
# Defines the build process, provisioners, and post-processors

# Build block - connects sources with provisioners
build {
  name = "fedora-${var.fedora_version}-${var.variant}"
  
  # Sources to build from
  sources = [
    "source.qemu.fedora"
  ]

  # Ansible provisioning
  # Note: System preparation (Python, updates, cleanup) is handled by kickstart %post section
  # Applies configuration using drts01 collection
  # Supports both local development (ANSIBLE_COLLECTIONS_PATH) and production (GitHub)
  provisioner "ansible" {
    playbook_file = "ansible/playbook-${var.variant}.yml"
    galaxy_file   = "ansible/requirements.yml"
    
    # Pass Fedora version to playbook
    extra_arguments = [
      "--extra-vars",
      "fedora_version=${var.fedora_version}"
    ]
    
    # Support for local collection development
    # Set ANSIBLE_COLLECTIONS_PATH environment variable to use local collections
    # Example: export ANSIBLE_COLLECTIONS_PATH=/path/to/local/collections
    ansible_env_vars = [
      "ANSIBLE_CONFIG=ansible/ansible.cfg",
      "ANSIBLE_FORCE_COLOR=1"
    ]
    
    # Use SSH for connection
    use_proxy = false
  }

  # Post-processor: Vagrant (optional, will be configured in task 11.1)
  # post-processor "vagrant" {
  #   output = "output/fedora-${var.fedora_version}-${var.variant}-{{.Provider}}.box"
  # }
}
