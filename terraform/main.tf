terraform {
  required_providers {
    opennebula = {
      source = "OpenNebula/opennebula"
      version = "0.4.1"
    }
  }
}

provider "opennebula" {
  endpoint      = var.one_endpoint
  flow_endpoint = var.one_flow_endpoint
  username      = var.one_username
  password      = var.one_password
}

module "instance-dev-tf" {
  source = "./modules/op_nb_instance"
  name = "test"
  cpu = 2
  vcpu = 2
  memory = 2048
  ssh_keys = var.ssh_keys
}
