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
  default = "https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "file:https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt"
}

variable "disk_size"    { default = "10G" }
variable "ssh_password" { default = "packer" }

source "qemu" "arch-cloud" {
  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  output_directory = "../../../images/x86_64/"
  vm_name          = "arch.qcow2"
  format           = "qcow2"
  disk_size        = var.disk_size
  disk_interface   = "virtio"
  disk_compression = true

  accelerator = "kvm"
  cpus        = 4
  memory      = 4096
  net_device  = "virtio-net"
  headless    = true    

  boot_wait = "30s"
  boot_command = [
    "<enter><wait20>",
    "echo 'root:${var.ssh_password}' | chpasswd<enter><wait>",
    "systemctl start sshd<enter><wait>"
  ]

  communicator = "ssh"
  ssh_username = "root"
  ssh_password = var.ssh_password
  ssh_timeout  = "20m"

  shutdown_command = "systemctl poweroff"
  qemuargs = [["-serial", "mon:stdio"]]
}

build {
  sources = ["source.qemu.arch-cloud"]

  provisioner "shell" {
    script          = "scripts/salt.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Path }}"
  }

  provisioner "shell" {
    script          = "scripts/base.sh"
    execute_command = "chmod +x {{ .Path }}; {{ .Path }}"
  }
}
