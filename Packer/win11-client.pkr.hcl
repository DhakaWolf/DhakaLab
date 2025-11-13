packer {
    required_plugins {
      vmware = {
        version = "~> 1"
        source = "github.com/hashicorp/vmware"
      }
    }
      required_plugins {
        windows-update = {
          version = ">= 0.15.0"
          source  = "github.com/rgl/windows-update"
      }
  }

source "vmware-iso" "Win11Build" {
  iso_url = var.iso_file_path
  iso_checksum = var.iso_checksum_value
  shutdown_command = "shutdown -t 0"
}

build {
  sources = [
    "source.vmware-iso.Win11Build"
  ]
}
}