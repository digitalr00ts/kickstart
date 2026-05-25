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
  default     = "40960"
  description = "Disk size in MB (default: 40GB)"
}

variable "memory" {
  type        = string
  default     = "2048"
  description = "Memory allocation in MB (default: 2GB)"
}

variable "cpus" {
  type        = string
  default     = "2"
  description = "Number of CPU cores"
}

variable "guest_arch" {
  type        = string
  default     = "x86_64"
  description = "Guest architecture to build (x86_64 or aarch64)"
  validation {
    condition     = contains(["x86_64", "aarch64"], var.guest_arch)
    error_message = "Guest architecture must be one of: x86_64, aarch64."
  }
}

variable "qemu_accelerator" {
  type        = string
  default     = "kvm"
  description = "QEMU accelerator to use (kvm, hvf, tcg, or none)"
  validation {
    condition     = contains(["kvm", "hvf", "tcg", "none"], var.qemu_accelerator)
    error_message = "Qemu accelerator must be one of: kvm, hvf, tcg, none."
  }
}

variable "qemu_binary" {
  type        = string
  default     = "qemu-system-x86_64"
  description = "QEMU system binary used by the builder"
}

variable "host_os_hint" {
  type        = string
  default     = "auto"
  description = "Optional host OS hint for build orchestration (auto, linux, macos)"
  validation {
    condition     = contains(["auto", "linux", "macos"], var.host_os_hint)
    error_message = "Host OS hint must be one of: auto, linux, macos."
  }
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
  default     = "3s"
  description = "Time to wait before typing boot command"
}

variable "http_directory" {
  type        = string
  default     = "http"
  description = "Directory containing kickstart files"
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether to run the build in headless mode (default: true)"
}
