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
  host_arch = lookup({
    aarch64 = "aarch64"
    arm64   = "aarch64"
    x86_64  = "x86_64"
    amd64   = "x86_64"
  }, lower(trimspace(var.host_arch)), "x86_64")
  host_os      = lower(trimspace(var.host_os))
  guest_arch   = trimspace(var.guest_arch) != "" ? var.guest_arch : local.host_arch
  host_os_hint = can(regex("^linux", local.host_os)) ? "linux" : can(regex("^darwin", local.host_os)) ? "macos" : "auto"
  host_defaults = {
    linux = {
      accelerator     = "kvm"
      aarch64_code_fd = "/usr/share/AAVMF/AAVMF_CODE.fd"
      aarch64_vars_fd = "/usr/share/AAVMF/AAVMF_VARS.fd"
    }
    macos = {
      accelerator     = "hvf"
      aarch64_code_fd = "/opt/homebrew/share/qemu/edk2-aarch64-code.fd"
      aarch64_vars_fd = "/opt/homebrew/share/qemu/edk2-arm-vars.fd"
    }
    auto = {
      accelerator     = "tcg"
      aarch64_code_fd = "/usr/share/AAVMF/AAVMF_CODE.fd"
      aarch64_vars_fd = "/usr/share/AAVMF/AAVMF_VARS.fd"
    }
  }
  host_defaults_for_hint = local.host_defaults[local.host_os_hint]
  qemu_binary            = "qemu-system-${local.guest_arch}"
  qemu_accelerator       = local.host_defaults_for_hint.accelerator
  aarch64_efi_code       = trimspace(var.aarch64_efi_firmware_code) != "" ? var.aarch64_efi_firmware_code : local.host_defaults_for_hint.aarch64_code_fd
  aarch64_efi_vars       = trimspace(var.aarch64_efi_firmware_vars) != "" ? var.aarch64_efi_firmware_vars : local.host_defaults_for_hint.aarch64_vars_fd
  qemu_display_mode      = lower(trimspace(var.qemu_display_mode))
  qemu_display_backend = local.qemu_display_mode != "auto" ? local.qemu_display_mode : (
    local.host_os_hint == "macos" ? "cocoa" :
    (local.host_os_hint == "linux" && local.guest_arch == "x86_64") ? "gtk" :
    (local.host_os_hint == "linux" && local.guest_arch == "aarch64") ? "vnc" :
    "none"
  )
  qemu_display_arg = lookup({
    none  = "none"
    gtk   = "gtk,gl=on"
    cocoa = "cocoa"
    sdl   = "sdl"
    vnc   = "vnc=:0"
  }, local.qemu_display_backend, "none")
  qemu_display_args = var.headless ? [] : [["-display", local.qemu_display_arg]]
}

source "qemu" "fedora" {
  iso_url      = var.fedora_iso_metadata[local.guest_arch][var.variant].url
  iso_checksum = var.fedora_iso_metadata[local.guest_arch][var.variant].checksum

  # aarch64/virt does not support BIOS-style boot device list handling.
  efi_boot          = local.guest_arch == "aarch64"
  efi_firmware_code = local.guest_arch == "aarch64" ? local.aarch64_efi_code : null
  efi_firmware_vars = local.guest_arch == "aarch64" ? local.aarch64_efi_vars : null

  # Output Configuration
  output_directory = "${var.output_directory}/qemu-${local.guest_arch}-${var.variant}"
  vm_name          = "fedora-${var.fedora_version}-${local.guest_arch}-${var.variant}"

  qemuargs = concat(
    local.guest_arch == "aarch64" ? [
      ["-machine", "virt"],
      ["-cpu", "max"],
      ] : [
      ["-machine", "q35"],
      ["-cpu", "host"],
    ],
    [
      # ["-chardev", "socket,id=serial0,path={{ .OutputDir }}/{{ .Name }}.console,server,nowait"],
      # ["-serial", "chardev:serial0"],
      # ["-device", "virtio-serial"],
    ],
    local.qemu_display_args,
  )

  # Hardware Configuration
  disk_size      = var.disk_size
  memory         = var.memory
  cpus           = var.cpus
  disk_interface = "virtio"
  net_device     = "virtio-net"

  # QEMU Specific Settings
  qemu_binary      = local.qemu_binary
  accelerator      = local.qemu_accelerator
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
    "<up>e",
    "<down><down><down><left><spacebar>",
    # "<bs><bs><bs><bs><bs>",
    "inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/${var.kickstart_file}<leftCtrlOn>x<leftCtrlOff>",
  ]

  shutdown_command = "sudo systemctl poweroff"

  headless = var.headless
}
