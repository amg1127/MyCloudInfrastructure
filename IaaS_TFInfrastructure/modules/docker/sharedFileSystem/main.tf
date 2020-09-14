# https://www.terraform.io/docs/providers/docker/r/volume.html

terraform {
    required_providers {
        docker = {
            source = "terraform-providers/docker"
        }
    }
}


resource "docker_volume" "dockerSharedVolume" {
    name = var.fileSystemName
}

locals {
    fileSystemID = docker_volume.dockerSharedVolume.name
}
