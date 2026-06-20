terraform {
  required_providers {
    twc = {
      source  = "timeweb-cloud/timeweb-cloud"
      version = "~> 1.6"
    }
  }
}

provider "twc" 

data "twc_image" "custom" {
  name      = "isp-base"
  is_custom = true
}

data "twc_configurator" "cfg" {
  location = "ru-1"
}

resource "twc_server" "vps" {
  name              = "metal-1"
  image_id          = data.twc_image.custom.id
  availability_zone = "msk-1"            

  configuration {
    configurator_id = data.twc_configurator.cfg.id
    disk            = 180 * 1024         
    cpu             = 4
    ram             = 8 * 1024           
  }
}

resource "twc_floating_ip" "v4" {
  availability_zone = "msk-1"            
  comment           = "isp-metal-1-ip-1"

  resource {
    type = "server"
    id   = twc_server.vps.id
  }
}
