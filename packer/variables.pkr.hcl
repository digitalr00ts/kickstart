# Packer Variable Definitions
# Variables used across all builders and provisioners

variable "fedora_version" {
  type        = string
  description = "Fedora release version"
}

variable "fedora_iso_metadata" {
  type = map(map(object({
    url      = string
    checksum = string
  })))
  description = "ISO metadata indexed by guest architecture and variant"
}

variable "variant" {
  type        = string
  default     = "server"
  description = "Image variant: server or workstation"
  validation {
    condition     = contains(["server", "workstation"], var.variant)
    error_message = "Variant must be either 'server' or 'workstation'."
  }
}

variable "output_directory" {
  type        = string
  default     = "output"
  description = "Directory for build artifacts"
}

variable "disk_size" {
  type        = string
  default     = "20480"
  description = "Disk size in MB (default: 20GB)"
}

variable "memory" {
  type        = string
  default     = "4096"
  description = "Memory allocation in MB (default: 4GB)"
}

variable "cpus" {
  type        = string
  default     = "2"
  description = "Number of CPU cores"
}

variable "guest_arch" {
  type        = string
  default     = ""
  description = "Guest architecture override. Empty derives from host_arch."
  validation {
    condition     = trimspace(var.guest_arch) == "" || contains(["x86_64", "aarch64"], var.guest_arch)
    error_message = "Guest architecture must be empty or one of: x86_64, aarch64."
  }
}

variable "host_arch" {
  type        = string
  default     = env("HOST_ARCH")
  description = "Host architecture hint. Pass `uname -m`. Defaults from HOST_ARCH when available."
}

variable "host_os" {
  type        = string
  default     = env("HOST_OS")
  description = "Host OS. Pass `uname -s`. Defaults from HOST_OS when available."
}

variable "aarch64_efi_firmware_code" {
  type        = string
  default     = ""
  description = "Optional path to ARM64 EFI firmware CODE file. Empty uses host-aware defaults."
}

variable "aarch64_efi_firmware_vars" {
  type        = string
  default     = ""
  description = "Optional path to ARM64 EFI firmware VARS file. Empty uses host-aware defaults."
}

variable "ssh_username" {
  type        = string
  default     = "vagrant"
  description = "SSH username for provisioning"
}

variable "ssh_password" {
  type        = string
  default     = "vagrant"
  description = "SSH password for provisioning (temporary)"
  sensitive   = true
}

variable "ssh_timeout" {
  type        = string
  default     = "30m"
  description = "SSH connection timeout"
}

variable "boot_wait" {
  type        = string
  default     = "5s"
  description = "Time to wait before typing boot command"
}

variable "http_directory" {
  type        = string
  default     = "http"
  description = "Directory containing kickstart files"
}

variable "kickstart_file" {
  type        = string
  default     = "ks-base.cfg"
  description = "Kickstart file"
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether to run the build in headless mode (default: true)"
}

variable "qemu_display_mode" {
  type        = string
  default     = "auto"
  description = "QEMU display backend when headless is false: auto, none, gtk, cocoa, sdl, or vnc."
  validation {
    condition = contains([
      "auto",
      "none",
      "gtk",
      "cocoa",
      "sdl",
      "vnc",
    ], lower(trimspace(var.qemu_display_mode)))
    error_message = "QEMU display mode must be one of: auto, none, gtk, cocoa, sdl, or vnc."
  }
}
