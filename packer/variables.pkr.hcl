# Packer Variable Definitions
# Variables used across all builders and provisioners

variable "fedora_version" {
  type        = string
  default     = "43"
  description = "Fedora release version"
}

variable "iso_url" {
  type        = string
  description = "URL to Fedora installation ISO"
}

variable "iso_checksum" {
  type        = string
  description = "SHA256 checksum of the ISO file"
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

variable "ssh_username" {
  type        = string
  default     = "root"
  description = "SSH username for provisioning"
}

variable "ssh_password" {
  type        = string
  default     = "packer"
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

variable "iso_url_server" {
  type        = string
  default     = null
  description = "URL to Fedora Server installation ISO (for server builds)"
}

variable "iso_checksum_server" {
  type        = string
  default     = null
  description = "SHA256 checksum of the Server ISO file"
}

variable "iso_url_workstation" {
  type        = string
  default     = null
  description = "URL to Fedora Workstation installation ISO (for workstation builds)"
}

variable "iso_checksum_workstation" {
  type        = string
  default     = null
  description = "SHA256 checksum of the Workstation ISO file"
}
