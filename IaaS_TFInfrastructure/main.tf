terraform {
    experiments = [variable_validation]
}

############# Naming configuration

# The domain name of the cloud network
variable "domain" {
    type = string
    description = "The domain name of the cloud network (example: 'example.com')"
}

# The environment that is being created
variable "environment" {
    type = string
    description = "The name of environment that is being created."
    validation {
        condition = can(regex("^[a-z](-?[a-z0-9]+)*$$", var.environment))
        error_message = "Variable environment is not valid."
    }
}

# The quantity of virtual hosts to be created
# These variables are being ignored currently because "module" statement does not support "count" parameter yet: https://github.com/hashicorp/terraform/issues/17519
variable "cloudLBServersCount" {
    type = number
    description = "Number of load balancers"
}

variable "cloudWWWServersCount" {
    type = number
    description = "Number of web servers"
}

variable "cloudMTAServersCount" {
    type = number
    description = "Number of e-mail servers"
}

variable "cloudAuthServersCount" {
    type = number
    description = "Number of authentication servers"
}

variable "cloudMonitServersCount" {
    type = number
    description = "Number of monitoring instances"
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

locals {
    SharedServerFileSystemMountPoint = "/srv"
}

# Step 1: the private network
module "privateLan" {
    source = "./modules/active/privateLan"
    v4CIDRBlock = var.privateLanV4CIDRBlock
}

# Step 2: a shared file system to be mounted by web and e-mail servers
module "sharedFileSystem" {
    source = "./modules/active/sharedFileSystem"
    fileSystemName = "${var.environment}_SharedServerFileSystem"
}

# Step 3: the load balancers
module "vmLoadBalancers" {
    source = "./modules/active/virtualMachine"
#    count = var.cloudLBHosts
#    hostName = "${var.environment}-lb${count.index}"
    hostName = "${var.environment}-lb"
    fixedIPv4 = true
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost(var.privateLanV4CIDRBlock, (var.privateLanStartIP + count.index))
    virtualMachinePrivIPv4 = cidrhost(var.privateLanV4CIDRBlock, var.privateLanStartIP)
    SSHKeyPairPath = var.SSHKeyPairPath
    sharedFileSystems = []
}

# Step 4: the authentication servers, next to the load balancers
module "vmAuthenticationServers" {
    source = "./modules/active/virtualMachine"
#    count = var.cloudAuthServersCount
#    hostName = "${var.environment}-auth${count.index}"
    hostName = "${var.environment}-auth"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmLoadBalancers[module.vmLoadBalancers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmLoadBalancers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
    sharedFileSystems = []
}

# Step 5: the monitoring servers, next to the authentication servers
module "vmMonitorServers" {
    source = "./modules/active/virtualMachine"
#    count = var.cloudMonitServersCount
#    hostName = "${var.environment}-monit${count.index}"
    hostName = "${var.environment}-monit"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmAuthenticationServers[module.vmAuthenticationServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmAuthenticationServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
    sharedFileSystems = []
}

# Step 6: the web servers, next to the monitoring servers
module "vmWWWServers" {
    source = "./modules/active/virtualMachine"
#    count = var.cloudWWWServersCount
#    hostName = "${var.environment}-www${count.index}"
    hostName = "${var.environment}-www"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmMonitorServers[module.vmMonitorServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmMonitorServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
    sharedFileSystems = [
        {
            fileSystemID = module.sharedFileSystem.fileSystemID
            mountPoint = local.SharedServerFileSystemMountPoint
        }
    ]
}

# Step 7: the e-mail servers, next to the web servers
module "vmMTAServers" {
    source = "./modules/active/virtualMachine"
#    count = var.cloudMTAServersCount
#    hostName = "${var.environment}-mx${count.index}"
    hostName = "${var.environment}-mx"
    privateLanID = module.privateLan.privateLanID
#    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmWWWServers[module.vmWWWServers.count-1].virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1 + count.index)
    virtualMachinePrivIPv4 = cidrhost (var.privateLanV4CIDRBlock, parseint( replace( module.vmWWWServers.virtualMachinePrivIPv4 , "/^.*[\\.:](\\d+)$$/", "$1"), 10) + 1)
    SSHKeyPairPath = var.SSHKeyPairPath
    sharedFileSystems = [
        {
            fileSystemID = module.sharedFileSystem.fileSystemID
            mountPoint = local.SharedServerFileSystemMountPoint
        }
    ]
}