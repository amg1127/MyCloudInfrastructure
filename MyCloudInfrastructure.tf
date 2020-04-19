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

############# Address assignment configuration

# The private and isolated network that test machines will use to communicate securely to each other
variable "privateTestLanV4CIDRBlock" {
    type = string
    description = "The RFC1918 network block to use internally (example: '192.168.1.0/24')"
}

# The private and isolated network that production machines will use to communicate securely to each other
variable "privateProdLanV4CIDRBlock" {
    type = string
    description = "The RFC1918 network block to use internally (example: '192.168.1.0/24')"
}

############# Security configuration

# Path to a SSH keypair to be used to authenticate as machine administrator
variable "SSHKeyPairPath" {
    type = string
    description = "A SSH keypair to be used to authenticate as machine administrator"
}

##############################################################################

# Test infrastructure
module "testInfrastructure" {
    source = "./IaaS_TFInfrastructure"
    environment = var.cloudTestSubdomainTest
    domain = var.cloudDomainName
    privateLanV4CIDRBlock = var.privateTestLanV4CIDRBlock
    SSHKeyPairPath = var.SSHKeyPairPath
    cloudLBServersCount = 2
    cloudWWWServersCount = 2
    cloudMTAServersCount = 2
    cloudAuthServersCount = 2
    cloudMonitServersCount = 1
}

# Production infrastructure
module "prodInfrastructure" {
    source = "./IaaS_TFInfrastructure"
    environment = var.cloudTestSubdomainProd
    domain = var.cloudDomainName
    privateLanV4CIDRBlock = var.privateProdLanV4CIDRBlock
    SSHKeyPairPath = var.SSHKeyPairPath
    cloudLBServersCount = 2
    cloudWWWServersCount = 3
    cloudMTAServersCount = 3
    cloudAuthServersCount = 2
    cloudMonitServersCount = 1
}
