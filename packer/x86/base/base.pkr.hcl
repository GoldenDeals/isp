packer {
  required_plugins {
    qemu = {
      version = "~> 1.1"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "iso_url" {
  type    = string
  default = "https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2.SHA256"
}

variable "disk_size" { default = "10G" }
variable "ssh_password" { default = "packer" }

source "qemu" "arch-cloud" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum
  disk_image   = true 

  output_directory = "../../../images/x86_64/base"
  vm_name          = "base.qcow2"
  format           = "qcow2"
  disk_size        = var.disk_size
  disk_interface   = "virtio"
  disk_compression = true

  accelerator = "kvm"
  cpus        = 4
  memory      = 4096
  net_device  = "virtio-net"
  headless    = true

  cd_label = "cidata"
  cd_content = {
    "meta-data" = "instance-id: packer-arch-base\nlocal-hostname: arch-base\n"
    "user-data" = <<-EOC
      #cloud-config
      ssh_pwauth: true
      users:
        - name: arch
          groups: [wheel]
          shell: /bin/bash
          lock_passwd: false
          plain_text_passwd: ${var.ssh_password}
          sudo: "ALL=(ALL) NOPASSWD:ALL"
    EOC
  }

  boot_wait = "20s"

  communicator = "ssh"
  ssh_username = "arch"
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"

  shutdown_command = "sudo systemctl poweroff"
  qemuargs         = [["-serial", "mon:stdio"]]
}

build {
  sources = ["source.qemu.arch-cloud"]

  provisioner "shell" {
    script          = "../../common/base.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Path }}"
  }
}
