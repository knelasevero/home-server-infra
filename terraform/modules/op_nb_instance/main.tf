terraform {
  required_providers {
    opennebula = {
      source = "OpenNebula/opennebula"
      version = "0.4.1"
    }
  }
}

data "opennebula_image" "debian" {
  name = "Debian 11"
}

data "opennebula_virtual_network" "kvmnet" {
  name = "kmvvirbr0"
}

resource "opennebula_virtual_machine" "instance" {
  count       = 1
  name        = var.name
  description = var.description
  cpu         = var.cpu
  vcpu        = var.vcpu
  memory      = var.memory
  permissions = var.permissions

  context = {
    HOSTNAME = var.name,
    ETH0_DNS = "1.1.1.1 8.8.8.8",
    ETH0_GATEWAY = "192.168.122.1",
    ETH0_IP = "192.168.122.3",
    ETH0_MASK = "255.255.255.0",
    ETH0_NETWORK = "192.168.122.0",
    NETWORK = "YES",
    SSH_PUBLIC_KEY = join("\n", var.ssh_keys),
    TARGET = "hda",
    START_SCRIPT = var.start_script
  }

  disk {
    image_id = data.opennebula_image.debian.id
    size     = var.disk
    driver   = "qcow2"
  }

  nic {
    network_id = data.opennebula_virtual_network.kvmnet.id
    # security_groups = [opennebula_security_group.mysecgroup.id]
    ip = var.ip
  }

#   vmgroup {
#     vmgroup_id = 42
#     role       = "vmgroup-role"
#   }

  tags = {
    environment = "dev"
  }

  timeout = 5
  lifecycle {
    ## Seems like a bug, we need to ignore this changes since they trigger runs everytime
    ignore_changes = [
      disk["volatile_format"]
    ]
  }
}