variable "one_endpoint" { default = "http://opnb.homeinfra:2633/RPC2" }
variable "one_username" {  }
variable "one_password" {  } 
variable "one_flow_endpoint" { default = "http://opnb.homeinfra:2474/RPC2" }
variable "ssh_keys" { default = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDEa9p1IvN/pfo/FyubRnfLvp19lbk7/Bp6vl0/znMGRW+u+mnZIvfT9QBWoGLrctzQD3o8RX/N29h4cGWW0goXC1ngNF8FxB1m7kmFiG6pUlJH8elKjDwum9qlT/xWWzaTE5qzOM9pWll5+JINJQydr29o20JFN+5W0/Sw4Lxg/aRS43QEGhX3ZoPOZOB+fe35ybtX5SH3cQU/X+5m+eW1EGZ3CGLwZxOXzPu0cS4wXt5rKLhg3sboWXZEJ4idmeXMQhrUPhsVbDrGReYzigQ2sSD8xfJDUFiwWrZ3mXYMLMEuJ3Goc6hRW96ltinhZEcf8nt2mhHAJHIlSwNpe97LTmAPaxJBgtMmHxUSUONESOb7accUiGe3a5yLsotQUcZjx/wm202/xgyPEUoqxzw/qb2ogXtaFRkjqY7eGqr4MkVPhGIkWhEkSRysOyY7mDtb8GbvYnokmg84mV22BQwoLkmddtM/2BQ+yevz/rnute8o6/Etpc+76U5yo6blebhsDBlBAMsNzxdTk/ugAaybQjbchbTDrUbXJlpRen/lnb9bZPcnWnqYjL5QOT0YQznOgvX5aSE6kQw4E4wcMW57bYjNx5rIehvaxBOe4J0vDDDmK0ImYiOUJw2K3nP/axRhiT/KI6L+wbOk1oCuizI8wIYFQMEcFs1Rx41lNGS5lw== lucas.alves@container-solutions.com",
    "another",
    ] }