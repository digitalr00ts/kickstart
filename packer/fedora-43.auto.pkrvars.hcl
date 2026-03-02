# Fedora 43 Specific Variables
# ISO URLs and checksums for Fedora 43

# Note: Update these URLs and checksums with actual Fedora 43 release values
# Get the latest from: https://getfedora.org/

# Fedora 43 Server ISO
# For server builds, use this ISO URL
iso_url_server = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-netinst-x86_64-43-1.6.iso"

# Fedora 43 Server ISO SHA256 checksum
# Verify from: https://getfedora.org/security/
iso_checksum_server = "sha256:16fd70ddae2c7de13e485637c3da1fb385dd8220389f988279ea3b3d561243cc"

# Fedora 43 Workstation ISO
# For workstation builds, use this ISO URL
iso_url_workstation = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Workstation/x86_64/iso/Fedora-Workstation-Live-43-1.6.x86_64.iso"

# Fedora 43 Workstation ISO SHA256 checksum
iso_checksum_workstation = "sha256:2a4a16c009244eb5ab2198700eb04103793b62407e8596f30a3e0cc8ac294d77"

# Fedora version
fedora_version = "43"

# IMPORTANT: Before building, update the ISO URLs and checksums above
# To get the actual checksums:
# 1. Visit https://getfedora.org/
# 2. Download the CHECKSUM file for your chosen ISO
# 3. Replace the placeholder checksums with actual values
#
# Example commands to verify checksums:
# wget https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/iso/Fedora-Server-43-1.1-x86_64-CHECKSUM
# sha256sum Fedora-Server-netinst-x86_64-43-1.1.iso
