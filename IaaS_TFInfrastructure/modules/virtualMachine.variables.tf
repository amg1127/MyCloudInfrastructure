# virtualMachine - This module is meant to create a virtual machine.

terraform {
    experiments = [variable_validation]
}

variable "hostName" {
    type = string
    description = "Name (and hostname) of the virtual machine to be created."
    validation {
        condition = can(regex("^[a-z](-?[a-z0-9]+)*$$", var.hostName))
        error_message = "Variable hostName is not valid."
    }
}

output "hostName" {
    value = var.hostName
}

variable "fixedIPv4" {
    type = bool
    description = "Force the public IPv4 to be fixed."
    default = false
}

output "fixedIPv4" {
    value = var.fixedIPv4
}

variable "privateLanID" {
    type = any
    description = "The ID of the private network that the virtual machine will be connected to."
}

output "privateLanID" {
    value = var.privateLanID
}

variable "virtualMachinePrivIPv4" {
    type = string
    description = "The private IPv4 address assigned to the virtual machine inside the private network referenced."
    validation {
        condition = can(regex("^(\\d+\\.){3}\\d+$$", var.virtualMachinePrivIPv4))
        error_message = "Variable virtualMachinePrivIPv4 is not valid."
    }
}

output "virtualMachinePrivIPv4" {
    value = var.virtualMachinePrivIPv4
}

variable "SSHPublicKeyPath" {
    type = string
    description = "Path to a SSH public key to be used to authenticate as machine administrator"
    validation {
        condition = can(regex("^\\w+(-\\w+)*\\s+\\w", file("${var.SSHPublicKeyPath}")))
        error_message = "Variable SSHPublicKeyPath is not valid."
    }
}

output "SSHPublicKeyPath" {
    value = var.SSHPublicKeyPath
}

variable "sharedFileSystems" {
    type = list (
        object ({
            fileSystemID = any
            mountPoint = string
        })
    )
    description = "A list of shared file systems to mount inside the virtual machine. Each item is a object containing the attributes 'fileSystemID' and 'mountPoint', which are respectively the ID of an already created shared file system and the path of the mount point."
}

output "sharedFileSystems" {
    value = var.sharedFileSystems
}

variable "serverRole" {
    type = string
    description = "Role of the server."
    validation {
        condition = can(regex("^\\w+$$", var.serverRole))
        error_message = "Variable serverRole is not valid."
    }
}

output "serverRole" {
    value = var.serverRole
}

