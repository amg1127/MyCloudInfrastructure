# sharedFileSystem - This module is meant to create a shared file system to be mounted by virtual machines.

output "fileSystemID" {
    value = local.fileSystemID
    description = "Name of the shared file system that has been created."
}
