terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  # Configuration options
  uri = "qemu:///system"
}


resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  target {
    path = var.libvirt_disk_path
  }
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = var.ubuntu_18_img_url
  format = "qcow2"
}



data "template_file" "user_data" {
  template = file("${path.module}/config/cloud_init.yml")
}

data "template_file" "network_config" {
  template = file("${path.module}/config/network_config.yml")
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = data.template_file.user_data.rendered
  network_config = data.template_file.network_config.rendered
  pool           = libvirt_pool.ubuntu.name
}

resource "libvirt_domain" "domain-ubuntu" {
  name   = var.vm_hostname
  memory = "4096"
  vcpu   = 4

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = var.vm_hostname
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello World' > /tmp/1",
      "sudo apt-get update",
      "sudo apt-get install -y mc python3-pip"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      host        = libvirt_domain.domain-ubuntu.network_interface[0].addresses[0]
      private_key = file(var.ssh_private_key)
      # bastion_host        = "myhost.ru"
      # bastion_user        = "deploys"
      # bastion_private_key = file("~/.ssh/deploys.pem")
      timeout = "1m"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
        echo "[nginx]" > nginx.ini
        echo "${libvirt_domain.domain-ubuntu.network_interface[0].addresses[0]}" >> nginx.ini
        echo "[nginx:vars]" >> nginx.ini
     #   echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand=\"ssh -W %h:%p -q myhost.ru\"'" >> nginx.ini
        echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null '" >> nginx.ini
        ansible-playbook -vvv -u ${var.ssh_username} --private-key ${var.ssh_private_key} -i nginx.ini ansible/playbook.yml
        EOT
  }


}

