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
  # ISO Configuration - automatically select based on variant
  iso_url      = var.variant == "server" ? var.iso_url_server : var.iso_url_workstation
  iso_checksum = var.variant == "server" ? var.iso_checksum_server : var.iso_checksum_workstation

  # Output Configuration
  output_directory = "${var.output_directory}/qemu-${var.variant}"
  vm_name          = "fedora-${var.fedora_version}-${var.variant}"
  
  qemuargs = [
    ["-chardev", "socket,id=serial0,path={{ .OutputDir }}/{{ .Name }}.console,server,nowait"],
    ["-serial", "chardev:serial0"],
    ["-device", "virtio-serial"],
  ]

  # Hardware Configuration
  disk_size      = var.disk_size
  memory         = var.memory
  cpus           = var.cpus
  disk_interface = "virtio"
  net_device     = "virtio-net"

  # QEMU Specific Settings
  accelerator = "kvm"
  format      = "qcow2"
  disk_compression = true

  # HTTP Server for Kickstart
  http_directory = var.http_directory
  http_port_min  = 8000
  http_port_max  = 8100

  # SSH Configuration
  ssh_username     = var.ssh_username
  ssh_password     = var.ssh_password
  ssh_timeout      = var.ssh_timeout
  ssh_wait_timeout = var.ssh_timeout
  
  vnc_use_password = true

  # Boot Configuration
  boot_wait = var.boot_wait
  boot_steps = [
    "<up>e<down><down><down><left><bs><bs><bs><bs><bs>",
    "inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-base.cfg<leftCtrlOn>x<leftCtrlOff>",
  ]

  # Shutdown Configuration
  shutdown_command = "sudo systemctl poweroff"

  # Headless mode (no GUI)
  headless = false
}
