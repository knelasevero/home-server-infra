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

data "template_file" "grptpl" {
  template = file("group_template.txt")
}

# Create a new group of users to the OpenNebula cluster
#resource "opennebula_group" "group" {
#    name                  = "test-group"
#    template              = data.template_file.grptpl.rendered
#    delete_on_destruction = true
#    quotas {
#        datastore_quotas {
#            id     = 1
#            images = 3
#            size   = 10000
#        }
#        vm_quotas {
#            cpu            = 3
#            running_cpu    = 3
#            memory         = 2048
#            running_memory = 2048
#        }
#    }
#}

module "instance-dev-tf" {
  source = "./modules/op_nb_instance"
  name = "test"
  cpu = 2
  vcpu = 2
  memory = 2048
  ssh_keys = var.ssh_keys
}
