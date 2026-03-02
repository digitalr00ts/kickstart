# Packer Source Blocks
# Define builders for different virtualization platforms

# Required Packer Plugins
packer {
  required_version = ">= 1.15.0"
  required_plugins {
    qemu = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/qemu"
    }
    virtualbox = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
    ansible = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/ansible"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

# QEMU/KVM Builder Source
source "qemu" "fedora" {
  # ISO Configuration
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  # Output Configuration
  output_directory = "${var.output_directory}/qemu-${var.variant}"
  vm_name          = "fedora-${var.fedora_version}-${var.variant}"

  # Hardware Configuration
  disk_size  = var.disk_size
  memory     = var.memory
  cpus       = var.cpus
  disk_interface = "virtio"
  net_device     = "virtio-net"

  # QEMU Specific Settings
  accelerator = "kvm"
  format      = "qcow2"

  # HTTP Server for Kickstart
  http_directory = var.http_directory
  http_port_min  = 8000
  http_port_max  = 8100

  # SSH Configuration
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  ssh_wait_timeout = var.ssh_timeout

  # Boot Configuration
  boot_wait = var.boot_wait
  boot_command = [
    "<up><tab> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-${var.variant}.cfg<enter><wait>"
  ]

  # Shutdown Configuration
  shutdown_command = "sudo systemctl poweroff"

  # Headless mode (no GUI)
  headless = true
}
