# privateLan - This module is meant to create a private and unrouteable network segment where virtual machine will exchange traffic.

terraform {
    experiments = [variable_validation]
}

variable "v4CIDRBlock" {
    type = string
    description = "IPv4 address block that the private network will use. It must be private addresses, as listed by RFC1918. Format: an IPv4 block in CIDR notation."
    validation {
        condition = can(regex("^(\\d+\\.){3}\\d+/\\d\\d?$$", var.v4CIDRBlock))
        error_message = "Variable v4CIDRBlock has been assigned an invalid IPv4 block."
    }
}

output "v4CIDRBlock" {
    value = var.v4CIDRBlock
}
