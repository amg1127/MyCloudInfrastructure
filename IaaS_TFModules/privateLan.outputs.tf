# privateLan - This module is meant to create a private and unrouteable network segment where virtual machine will exchange traffic.

output "privateLanID" {
    value = local.privateLanID
    description = "The ID of the private network."
}
