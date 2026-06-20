packer {
  required_plugins {
    incus = {
      source  = "github.com/bketelsen/incus"
      version = "~> 1"
    }
  }
}

source "incus" "debian-base" {
  image        = "images:debian/13"
  output_image = "router"
  reuse        = true           

  publish_properties = {
    description = "Router image for project https://github.com/GoldenDeals/isp"
  }

  launch_config = {
    "security.nesting" = "true"
  }
}

build {
  sources = ["incus.debian-base"]

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update",
      "apt-get install -y curl ca-certificates",
      "apt-get clean",
    ]
  }
}
