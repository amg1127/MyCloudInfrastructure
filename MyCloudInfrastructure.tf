############# Naming configuration

# The domain name of the cloud network
variable "cloudDomainName" {
    type = string
    description = "The domain name of the cloud network (example: 'example.com')"
}

# The subdomain component of the cloud network for testing environment
variable "cloudTestSubdomainTest" {
    type = string
    description = "The subdomain component of the cloud network for testing environment"
    default = "test"
}

# The subdomain component of the cloud network for production environment
variable "cloudTestSubdomainProd" {
    type = string
    description = "The subdomain component of the cloud network for production environment"
    default = "prod"
}

# The quantity of virtual hosts to be created
# These variables are being ignored currently because "module" statement does not support "count" parameter yet: https://github.com/hashicorp/terraform/issues/17519
variable "cloudLBServersCount" {
    type = number
    description = "Number of load balancers"
    default = 2
}
variable "cloudWWWServersCount" {
    type = number
    description = "Number of web servers"
    default = 3
}
variable "cloudMTAServersCount" {
    type = number
    description = "Number of e-mail servers"
    default = 3
}
variable "cloudAuthServersCount" {
    type = number
    description = "Number of authentication servers"
    default = 2
}
variable "cloudMonitServersCount" {
    type = number
    description = "Number of monitoring instances"
    default = 1
}

############# Address assignment configuration

# The private and isolated network that machines will use to communicate securely to each other
variable "privateLanV4CIDRBlock" {
    type = string
    description = "The RFC1918 network block to use internally (example: '192.168.1.0/24')"
}

# This number defines the last octet of the first IP address to be allocated inside the private network
variable "privateLanStartIP" {
    type = number
    description = "The last octet of the first IP address to be allocated inside the private network"
    default = 4
}

############# Security configuration
# Path to a SSH keypair to be used to authenticate as machine administrator
variable "SSHKeyPairPath" {
    type = string
    description = "A SSH keypair to be used to authenticate as machine administrator"
}

##############################################################################

# Step 1: the private network
module "privateLan" {
    source = "./IaaS_TFModules/active/privateLan"
    v4CIDRBlock = var.privateLanV4CIDRBlock
}

# Step 2: the load balancers
module "vmLoadBalancers" {
    source = "./IaaS_TFModules/active/virtualMachine"
#    count = var.cloudLBHosts
#    hostName = "lb${count.index}"
    hostName = "lb"
    fixedIPv4 = true
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost(var.privateLanV4CIDRBlock, (var.privateLanStartIP + count.index))
    virtualMachinePrivIPv4 = cidrhost(var.privateLanV4CIDRBlock, var.privateLanStartIP)
    SSHKeyPairPath = var.SSHKeyPairPath
}

# Step 3: the authentication servers, next to the load balancers
module "vmAuthenticationServers" {
    source = "./IaaS_TFModules/active/virtualMachine"
#    count = var.cloudAuthServersCount
#    hostName = "auth${count.index}"
    hostName = "auth"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmLoadBalancers[module.vmLoadBalancers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmLoadBalancers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
}

# Step 4: the monitoring servers, next to the authentication servers
module "vmMonitorServers" {
    source = "./IaaS_TFModules/active/virtualMachine"
#    count = var.cloudMonitServersCount
#    hostName = "monit${count.index}"
    hostName = "monit"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmAuthenticationServers[module.vmAuthenticationServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmAuthenticationServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
}

# Step 5: the web servers, next to the monitoring servers
module "vmWWWServers" {
    source = "./IaaS_TFModules/active/virtualMachine"
#    count = var.cloudWWWServersCount
#    hostName = "www${count.index}"
    hostName = "www"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmMonitorServers[module.vmMonitorServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmMonitorServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
}


# Step 6: the e-mail servers, next to the web servers
module "vmMTAServers" {
    source = "./IaaS_TFModules/active/virtualMachine"
#    count = var.cloudMTAServersCount
#    hostName = "mx${count.index}"
    hostName = "mx"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmWWWServers[module.vmWWWServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmWWWServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
}
