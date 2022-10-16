packer {
  required_version = "~>1.7"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
    vagrant = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/vagrant"
    }
    virtualbox = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/virtualbox"
    }
  }
}

source "qemu" "fedora" {
  headless    = "${var.headless}"
  accelerator = "kvm"
  qmp_enable  = true
  qemuargs = [
    ["-chardev", "socket,id=serial0,path={{ .OutputDir }}/{{ .Name }}.console,server,nowait"],
    ["-serial", "chardev:serial0"],
    ["-spice", "unix,addr={{ .OutputDir }}/{{ .Name }}.spice,disable-ticketing"],
    ["-device", "virtio-serial"],
    ["-chardev", "spicevmc,id=vdagent,debug=0,name=vdagent"],
    ["-device", "virtserialport,chardev=vdagent,name=com.redhat.spice.0"],
  ] // "
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

source "virtualbox-iso" "fedora" {
  guest_os_type           = "Fedora_64"
  headless                = var.headless
  iso_url                 = local.iso_url
  iso_checksum            = local.iso_checksum
  output_directory        = "output/{{build_type}}"
  ssh_timeout             = "60000s"
  ssh_username            = "vagrant"
  ssh_password            = "${var.password}"
  vm_name                 = "Fedora${var.version}"
  cpus                    = "2"
  memory                  = "1024"
  gfx_controller          = "vmsvga"
  gfx_vram_size           = "8"
  disk_size               = "10240"
  hard_drive_discard      = true
  audio_controller        = "hda"
  guest_additions_mode    = "attach"
  virtualbox_version_file = ""
  http_directory          = "kickstart"
  boot_wait               = "3s"
  boot_command = [
    "<up><tab><wait>",
    "<bs><bs><bs><bs><bs>",
    "inst.text ",
    // "inst.sshd ",
    // "inst.nokill ",
    "inst.notmux ",
    "inst.ksstrict ",
    "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg",
    // "inst.nosave=all ",
    "<enter>",
  ]
  shutdown_command = "echo '${var.password}' | sudo -S shutdown -P now"
}

build {
  name        = "Fedora"
  description = "Fedora"
  sources = [
    "source.qemu.fedora",
    "source.virtualbox-iso.fedora",
  ]

  // provisioner "ansible" {
  //   playbook_file       = "playbooks/site.yaml"
  //   extra_arguments     = ["-v"]
  //   user                = "packer"
  //   galaxy_file         = "requirements.yaml"
  //   keep_inventory_file = true
  //   ansible_ssh_extra_args = [
  //     "-o 'HostKeyAlgorithms ssh-rsa' ",
  //     "-o IdentitiesOnly=yes"
  //   ]
  // }

  /*
  provisioner "inspec" {
    inspec_env_vars = ["CHEF_LICENSE=accept"]
    profile         = "https://github.com/dev-sec/linux-baseline"
  }
*/

  post-processors {
    post-processor "vagrant" {
      // name                           = "box"
      include = ["packer/info.json"]
      // vagrantfile_template_generated = true
      output              = "output/boxes/{{.BuildName}}${var.version}_{{.Provider}}.box"
      keep_input_artifact = true
      compression_level   = 9
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
