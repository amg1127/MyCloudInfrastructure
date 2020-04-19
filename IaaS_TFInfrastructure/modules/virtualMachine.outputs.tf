# virtualMachine - This module is meant to create a virtual machine.

output "virtualMachineID" {
    value = local.virtualMachineID
    description = "The ID of the virtual machine."
}

output "virtualMachinePubIPv4" {
    value = local.virtualMachinePubIPv4
    description = "The public IPv4 assigned to the virtual machine for further connection and provision."
}
