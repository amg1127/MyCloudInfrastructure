# https://www.terraform.io/docs/providers/docker/r/network.html

resource "docker_network" "privateLan" {
    name = "lan_${replace(var.v4CIDRBlock, "/\\D+/", "_")}"
    driver = "bridge"
    options = {
        enable_icc = true
    }
    internal = true
    attachable = true
    ipam_config {
        subnet = var.v4CIDRBlock
    }
}

locals {
    privateLanID = docker_network.privateLan.id
}
