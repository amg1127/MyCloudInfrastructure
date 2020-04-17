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

variable "SSHKeyPairPath" {
    type = string
    description = "Path to a SSH keypair to be used to authenticate as machine administrator"
    validation {
        condition = can(regex("^\\w+(-\\w+)*\\s+\\w", file("${var.SSHKeyPairPath}.pub")))
        error_message = "Variable SSHKeyPairPath is not valid."
    }
}

locals {
    SSHPrivateKeyPath = var.SSHKeyPairPath
    SSHPublicKeyPath = "${var.SSHKeyPairPath}.pub"
}

output "SSHKeyPairPath" {
    value = var.SSHKeyPairPath
}

