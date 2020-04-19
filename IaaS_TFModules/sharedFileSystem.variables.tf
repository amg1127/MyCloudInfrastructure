# sharedFileSystem - This module is meant to create a shared file system to be mounted by virtual machines.

variable "fileSystemName" {
    type = string
    description = "Name of the shared file system to be created."
    default = null
}

output "fileSystemName" {
    value = var.fileSystemName
}
