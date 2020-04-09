# The private and isolated network that machines will use to communicate securely to each other
variable "privateLanV4CIDRBlock" {
    type = string
    description = "The RFC1918 network block to use internally"
    default = ""
}
module "privateLan" {
    source = "./IaaS_TFModules/active/privateLan"
    v4CIDRBlock = var.privateLanV4CIDRBlock
}
