
variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  default     = "/kvm/images"
}

variable "ubuntu_18_img_url" {
  description = "ubuntu 18.04 image"
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_hostname" {
  description = "vm hostname"
  default     = "terraform-kvm-ansible"
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "/kvm/kvm-ansible/id_rsa"
}

