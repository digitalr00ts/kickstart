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
  default = "32"
  type    = string
}
variable "release" {
  default = "1.6"
  type    = string
}
variable "password" {
  default = "vagrant"
  type    = string
}

locals {
  media        = {
    "server"      = "dvd"
    "workstation" = "Live"
    "boot"         = "netinst"
  }
  type         = "${var.type == "boot" ? "everything" : lower(var.type)}"
  reltype      = "${var.version == "Rawhide" ? "development" : "releases"}"
  iso_base     = "https://download.fedoraproject.org/pub/fedora/linux/${local.reltype}/${lower(var.version)}/${title(local.type)}/x86_64/iso"
  iso_url      = "${local.iso_base}/Fedora-${title(local.type)}-${lookup(local.media, lower(var.type), title(var.type))}-x86_64-${var.version}-${var.release}.iso"
  # iso_checksum = "file:${local.iso_base}/Fedora-${title(local.type)}-${var.version}-${var.release}-x86_64-CHECKSUM"
  iso_checksum = "file:${local.iso_base}/Fedora-${title(local.type)}-${var.version}-x86_64-${var.release}-CHECKSUM"
}

source "qemu" "fedora" {
  headless           = "${var.headless}"
  accelerator        = "kvm"
  qmp_enable         = true
  qemuargs           = [
    ["-chardev", "socket,id=serial0,path={{ .OutputDir }}/{{ .Name }}.console,server,nowait"],
    ["-serial",  "chardev:serial0"],
    ["-spice",   "unix,addr={{ .OutputDir }}/{{ .Name }}.spice,disable-ticketing"],
    ["-device",  "virtio-serial"],
    ["-chardev", "spicevmc,id=vdagent,debug=0,name=vdagent"],
    ["-device",  "virtserialport,chardev=vdagent,name=com.redhat.spice.0"],
  ]
  vnc_use_password   = true
  iso_url            = "${local.iso_url}"
  iso_checksum       = "${local.iso_checksum}"
  output_directory   = "output/{{build_type}}"
  ssh_timeout        = "60000s"
  ssh_wait_timeout   = "60000s"
  ssh_username       = "vagrant"
  ssh_password       = "${var.password}"
  vm_name            = "fedora${var.version}"
  cpus               = "2"
  memory             = "1024"
  disk_compression   = true
  disk_detect_zeroes = "unmap"
  disk_discard       = "unmap"
  disk_size          = "10240M"
  http_directory     = "kickstart"
  boot_key_interval  = "10ms"
  boot_wait          = "1s"
  boot_command       = ["<tab> console=ttyS0,115200n8 inst.text inst.sshd ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"]
  // shutdown_command   = "echo '${var.password}' | sudo -S shutdown -P now"
}

build {
  name        = "Fedora"
  description = "Fedora"
  sources     = ["source.qemu.fedora"]

  provisioner "ansible" {
    playbook_file = "playbooks/site.yml"
  }

/*
  provisioner "inspec" {
    inspec_env_vars = ["CHEF_LICENSE=accept"]
    profile         = "https://github.com/dev-sec/linux-baseline"
  }
*/

  post-processors {
    post-processor "vagrant" {
      name                           = "box"
      include                        = ["packer/info.json"]
      vagrantfile_template_generated = true
      output                         = "output/boxes/{{.BuildName}}${var.version}_{{.Provider}}.box"
      keep_input_artifact            = true
    }
    post-processor "checksum" {
      name           = "sha256"
      checksum_types = ["sha256"]
      output         = "output/boxes/{{.BuildName}}${var.version}.checksum"
    }
    post-processor "manifest" {
      strip_path = true
    }
  }
}
