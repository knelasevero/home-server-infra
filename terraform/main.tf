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

module "control-dev-tf" {
  source = "./modules/op_nb_instance"
  name = "control-dev"
  cpu = 2
  vcpu = 2
  memory = 7168
  ssh_keys = var.ssh_keys
  ip = "192.168.122.2"
  start_script = "echo '192.168.122.2 control.opnb.homeinfra' >> /etc/hosts && hostname control.opnb.homeinfra"
}

module "node1-dev-tf" {
  source = "./modules/op_nb_instance"
  name = "node1-dev"
  cpu = 1
  vcpu = 1
  memory = 4096
  ssh_keys = var.ssh_keys
  ip = "192.168.122.3" 
  start_script = "echo '192.168.122.2 control.opnb.homeinfra' >> /etc/hosts && hostname node1.opnb.homeinfra"
}

module "node2-dev-tf" {
  source = "./modules/op_nb_instance"
  name = "node2-dev"
  cpu = 1
  vcpu = 1
  memory = 4096
  ssh_keys = var.ssh_keys
  ip = "192.168.122.4" 
  start_script = "echo '192.168.122.2 control.opnb.homeinfra' >> /etc/hosts && hostname node2.opnb.homeinfra"
}