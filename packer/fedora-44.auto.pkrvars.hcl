fedora_version = "44"

fedora_iso_metadata = {
  x86_64 = {
    server = {
      url      = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/x86_64/iso/Fedora-Server-netinst-x86_64-44-1.7.iso"
      checksum = "sha256:ae20c06bea746913cadea7d80463e13f4bf55bee4df2918111c921c674b70283"
    }
    workstation = {
      url      = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/x86_64/iso/Fedora-Workstation-Live-44-1.7.x86_64.iso"
      checksum = "sha256:1620295f6a00c27c3208f0c00b8ece4eab1ec69b9002152d97488bf26a426ddf"
    }
  }

  aarch64 = {
    server = {
      url      = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Server/aarch64/iso/Fedora-Server-netinst-aarch64-44-1.7.iso"
      checksum = "sha256:a93ebd0322cda5a439039710b727ac1899a06e1c11876cfdf7f27c25b8262cc3"
    }
    workstation = {
      url      = "https://download.fedoraproject.org/pub/fedora/linux/releases/44/Workstation/aarch64/iso/Fedora-Workstation-Live-44-1.7.aarch64.iso"
      checksum = "sha256:162ba3c552a2d241c7c63ec26777af0255ee1b5a135adc0be986ceed999933ef"
    }
  }
}
