variable "name" { default = "control" }
variable "description" { default = "instance created by terraform" }
variable "cpu" { default = 1 }
variable "vcpu" { default = 1 }
variable "memory" { default = 1024 }
variable "permissions" { default = "660" }
variable "ssh_keys" { default = [] }