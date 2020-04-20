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
    administrativeSSHUser = "root"
    sharedServerFileSystemMountPoint = "/srv"
    SSHPrivateKeyPath = var.SSHKeyPairPath
    SSHPublicKeyPath = "${var.SSHKeyPairPath}.pub"
    AnsibleBootstrapSourceFolder = "./AnsibleSetup"
    AnsibleBootstrapDestinationFolder = "/tmp"
    AnsibleBootstrapPlaybookSource = "${local.AnsibleBootstrapSourceFolder}/AnsibleBootstrapPlaybook.yml"
    AnsibleBootstrapPlaybookDestination = "${local.AnsibleBootstrapDestinationFolder}/AnsibleBootstrapPlaybook.yml"
    AnsibleBootstrapScriptSource = "${local.AnsibleBootstrapSourceFolder}/AnsibleBootstrap.sh"
    AnsibleBootstrapScriptDestination = "${local.AnsibleBootstrapDestinationFolder}/AnsibleBootstrap.sh"
    AnsibleBootstrapVariablesSource = "${local.AnsibleBootstrapSourceFolder}/AnsibleBootstrapVariables.yml"
    AnsibleBootstrapVariablesDestination = "${local.AnsibleBootstrapDestinationFolder}/AnsibleBootstrapVariables.yml"
    AnsibleSystemConfigFolder = "/etc/ansible"
    AnsibleSystemInventoryFile = "${local.AnsibleSystemConfigFolder}/hosts"
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
    SSHPublicKeyPath = local.SSHPublicKeyPath
    sharedFileSystems = []
    serverRole = "LoadBalancer"
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
    SSHPublicKeyPath = local.SSHPublicKeyPath
    sharedFileSystems = []
    serverRole = "AuthenticationServer"
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
    SSHPublicKeyPath = local.SSHPublicKeyPath
    sharedFileSystems = []
    serverRole = "MonitorServer"
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
    SSHPublicKeyPath = local.SSHPublicKeyPath
    sharedFileSystems = [
        {
            fileSystemID = module.sharedFileSystem.fileSystemID
            mountPoint = local.sharedServerFileSystemMountPoint
        }
    ]
    serverRole = "WebServer"
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
    SSHPublicKeyPath = local.SSHPublicKeyPath
    sharedFileSystems = [
        {
            fileSystemID = module.sharedFileSystem.fileSystemID
            mountPoint = local.sharedServerFileSystemMountPoint
        }
    ]
    serverRole = "MailServer"
}

# Step 8: configure Ansible in all virtual machines, using provision of null resources
# https://github.com/hashicorp/terraform/issues/22281
locals {
    allVirtualMachines = flatten([
        module.vmLoadBalancers,
        module.vmAuthenticationServers,
        module.vmMonitorServers,
        module.vmWWWServers,
        module.vmMTAServers
    ])
    allServerRoles = sort(distinct([for m in local.allVirtualMachines : m.serverRole]))
}

resource "null_resource" "AnsibleBootstrap" {
    for_each = { for k in local.allVirtualMachines : k.hostName => k.virtualMachinePubIPv4 }

    connection {
        type = "ssh"
        user = local.administrativeSSHUser
        host = each.value
        private_key = file(local.SSHPrivateKeyPath)
    }

    triggers = {
        vmPublicIP = each.value
    }

    # Generation and upload of an inventory file
    provisioner "file" {
        /* This code block raises syntax error - https://github.com/hashicorp/terraform/issues/24711
        content = <<-ANSIBLEINVENTORY
        # This file has been generated dynamically by Terraform.
        # Beware: it can be overwritten anytime...

        all:
          hosts:
            localhost:
              ansible_connection: local
            children:
              {~% for sr in local.allServerRoles ~}
              ${sr}:
                hosts:
                {~% for vm in local.AllVirtualMachines ~}
                  {~% if sr == vm.serverRole ~}
                  ${vm.hostName}:
                    ansible_host: "${vm.virtualMachinePrivIPv4}"
                  {~% endif ~}
                {~% endfor ~}
              {~% endfor ~}
          vars:
            ansible_python_interpreter: "/usr/bin/python3"
        ANSIBLEINVENTORY
        */

        content = <<-ANSIBLEINVENTORY
        # This file has been generated dynamically by Terraform.
        # Beware: it can be overwritten anytime...

        all:
          hosts:
            localhost:
              ansible_connection: local
          vars:
            ansible_python_interpreter: "/usr/bin/python3"
        ANSIBLEINVENTORY

        destination = local.AnsibleSystemInventoryFile
    }

    # Upload of the bootstrap playbook
    provisioner "file" {
        source = local.AnsibleBootstrapPlaybookSource
        destination = local.AnsibleBootstrapPlaybookDestination
    }

    # Upload of the bootstrap variables file
    provisioner "file" {
        source = local.AnsibleBootstrapScriptSource
        destination = local.AnsibleBootstrapScriptDestination
    }

    # Upload of the bootstrap script
    provisioner "file" {
        source = local.AnsibleBootstrapVariablesSource
        destination = local.AnsibleBootstrapVariablesDestination
    }

    provisioner "remote-exec" {
        # Bootstrap Ansible playbook from here
        inline = [
            "/usr/bin/ansible-playbook --verbose --extra-vars \"@${local.AnsibleBootstrapVariablesDestination}\" --extra-vars \"AnsibleBootstrapScriptSource=${local.AnsibleBootstrapScriptDestination}\" \"${local.AnsibleBootstrapPlaybookDestination}\""
        ]
    }
}

