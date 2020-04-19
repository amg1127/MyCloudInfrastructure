#### VARIABLES THAT CONFIGURE MY CLOUD INFRASTRUCTURE ####

# The subdomain component of the cloud network for testing environment
cloudDomainName = "andersongomes.tech"

# The RFC1918 network blocks to use internally
privateTestLanV4CIDRBlock = "10.101.0.0/20"
privateProdLanV4CIDRBlock = "10.202.0.0/20"

# Path to a SSH keypair to be used to authenticate as machine administrator
SSHKeyPairPath = "./private/administrative-ssh-keypair"
