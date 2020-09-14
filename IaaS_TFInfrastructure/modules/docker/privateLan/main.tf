# https://www.terraform.io/docs/providers/docker/r/network.html

terraform {
    required_providers {
        docker = {
            source = "terraform-providers/docker"
        }
    }
}


resource "docker_network" "privateDockerNetwork" {
    name = "privLan_${replace(var.v4CIDRBlock, "/\\D+/", "_")}"
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
    privateLanID = docker_network.privateDockerNetwork.id
}
