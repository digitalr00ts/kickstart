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

locals {
  host_arch_from_uname_m = lookup({
    aarch64 = "aarch64"
    arm64   = "aarch64"
    x86_64  = "x86_64"
    amd64   = "x86_64"
  }, lower(trimspace(var.host_uname_m)), "x86_64")
  host_os_hint_from_uname_s = lookup({
    linux  = "linux"
    darwin = "macos"
  }, lower(trimspace(var.host_uname_s)), "auto")
  effective_guest_arch   = trimspace(var.guest_arch) != "" ? var.guest_arch : local.host_arch_from_uname_m
  effective_host_os_hint = trimspace(var.host_os_hint) != "" ? var.host_os_hint : local.host_os_hint_from_uname_s
  qemu_accelerator_default_by_host = {
    linux = "kvm"
    macos = "hvf"
    auto  = "tcg"
  }
  effective_qemu_binary             = trimspace(var.qemu_binary) != "" ? var.qemu_binary : "qemu-system-${local.effective_guest_arch}"
  effective_qemu_accelerator        = trimspace(var.qemu_accelerator) != "" ? var.qemu_accelerator : lookup(local.qemu_accelerator_default_by_host, local.effective_host_os_hint, "tcg")
  aarch64_efi_firmware_code_default = local.effective_host_os_hint == "macos" ? "/opt/homebrew/share/qemu/edk2-aarch64-code.fd" : "/usr/share/AAVMF/AAVMF_CODE.fd"
  aarch64_efi_firmware_vars_default = local.effective_host_os_hint == "macos" ? "/opt/homebrew/share/qemu/edk2-arm-vars.fd" : "/usr/share/AAVMF/AAVMF_VARS.fd"
  aarch64_efi_firmware_code         = trimspace(var.aarch64_efi_firmware_code) != "" ? var.aarch64_efi_firmware_code : local.aarch64_efi_firmware_code_default
  aarch64_efi_firmware_vars         = trimspace(var.aarch64_efi_firmware_vars) != "" ? var.aarch64_efi_firmware_vars : local.aarch64_efi_firmware_vars_default
}

source "qemu" "fedora" {
  # ISO Configuration - automatically select based on variant
  iso_url      = var.fedora_iso_metadata[local.effective_guest_arch][var.variant].url
  iso_checksum = var.fedora_iso_metadata[local.effective_guest_arch][var.variant].checksum

  # aarch64/virt does not support BIOS-style boot device list handling.
  efi_boot          = local.effective_guest_arch == "aarch64"
  efi_firmware_code = local.effective_guest_arch == "aarch64" ? local.aarch64_efi_firmware_code : null
  efi_firmware_vars = local.effective_guest_arch == "aarch64" ? local.aarch64_efi_firmware_vars : null

  # Output Configuration
  output_directory = "${var.output_directory}/qemu-${local.effective_guest_arch}-${var.variant}"
  vm_name          = "fedora-${var.fedora_version}-${local.effective_guest_arch}-${var.variant}"

  qemuargs = concat(
    local.effective_guest_arch == "aarch64" ? [
      ["-machine", "virt"],
      ["-cpu", "max"],
      ] : [
      ["-machine", "q35"],
      ["-cpu", "host"],
    ],
    [
      ["-chardev", "socket,id=serial0,path={{ .OutputDir }}/{{ .Name }}.console,server,nowait"],
      ["-serial", "chardev:serial0"],
      ["-device", "virtio-serial"],
    ]
  )

  # Hardware Configuration
  disk_size      = var.disk_size
  memory         = var.memory
  cpus           = var.cpus
  disk_interface = "virtio"
  net_device     = "virtio-net"

  # QEMU Specific Settings
  qemu_binary      = local.effective_qemu_binary
  accelerator      = local.effective_qemu_accelerator
  format           = "qcow2"
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
  boot_command = [
    "<up>e<down><down><down><left><bs><bs><bs><bs><bs>",
    "inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks-base.cfg<leftCtrlOn>x<leftCtrlOff>",
  ]

  # Shutdown Configuration
  shutdown_command = "sudo systemctl poweroff"

  # Headless mode (no GUI)
  headless = var.headless
}
