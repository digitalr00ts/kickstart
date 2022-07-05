
variable "headless" {
  default = true
  type    = bool
}
variable "type" {
  default     = "boot"
  type        = string
  description = "Server, Workstation, or Boot"
}
variable "version" {
  default = "Rawhide"
  type    = string
}
variable "release" {
  default = "20220506.n.0"
  type    = string
}
variable "password" {
  default = "vagrant"
  type    = string
}

locals {
  media = {
    "server"      = "dvd"
    "workstation" = "Live"
    "boot"        = "netinst"
  }
  type         = "${var.type == "boot" ? "everything" : lower(var.type)}"
  reltype      = "${var.version == "Rawhide" ? "development" : "releases"}"
  iso_base     = "https://download.fedoraproject.org/pub/fedora/linux/${local.reltype}/${lower(var.version)}/${title(local.type)}/x86_64/iso"
  iso_url      = "${local.iso_base}/Fedora-${title(local.type)}-${lookup(local.media, lower(var.type), title(var.type))}-x86_64-${var.version}-${var.release}.iso"
  iso_checksum = "file:${local.iso_base}/Fedora-${title(local.type)}-${var.version}-${var.release}-x86_64-CHECKSUM"
  //   iso_checksum = "file:${local.iso_base}/Fedora-${title(local.type)}-${var.version}-x86_64-${var.release}-CHECKSUM"
}
