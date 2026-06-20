packer {
  required_plugins {
    incus = {
      source  = "github.com/bketelsen/incus"
      version = "~> 1"
    }
  }
}

source "incus" "arch-base" {
  image        = "images:archlinux/current/cloud"
  output_image = "isp-base"
  reuse        = true

  publish_properties = {
    description = "Arch Linux base image for project https://github.com/GoldenDeals/isp"
  }

  launch_config = {
    "security.nesting" = "true"
  }
}

build {
  sources = ["incus.arch-base"]

  provisioner "shell" {
    inline = ["pacman -Sy --needed --noconfirm sudo openssh"]
  }

  provisioner "shell" {
    script          = "../../common/base.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Path }}"
  }
}
