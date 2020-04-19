# https://www.terraform.io/docs/providers/docker/r/volume.html

resource "docker_volume" "dockerSharedVolume" {
    name = var.fileSystemName
}

locals {
    fileSystemID = docker_volume.dockerSharedVolume.name
}
