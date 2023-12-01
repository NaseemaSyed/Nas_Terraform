#_________________Setup Vars__________________
variable "location" {
description = "Which region in Azure are we launching the resources"
default = "West Europe"
}

variable "name" {
description = "Base name for resources"
default = "iac-wordpress"
}
variable "environment_type" {
description = "type of the environment we are building"
default = "dev"
}


variable "default_tags" {
description = "The default tags to use across all of our resources"
type = map(any) #“map” is a data structure used to represent a collection of key-value pairs, https://spacelift.io/blog/terraform-map-variable
default = {
project = "iac-wordpress"
environment = "dev"
deployed_by = "terraform"
}
}

#_________________Networking Vars__________________

variable "vnet_address_space" {
description = "The address space of vnet"
type = list(any)
default = ["10.0.0.0/24"]
}

variable "vnet_subnets" {
description = "The subnets to deploy in the vnet"
type = map(object({
subnet_name = string
address_prefix = string
private_endpoint_network_policies_enabled = bool
service_endpoints = list(string)
service_delegations = map(map(list(string)))
}))
    # used in our deployment, starting with the subnet for the virtual machines:
default = {
virtual_network_subnets_001 = {
subnet_name = "vms"
address_prefix = "10.0.0.0/27"
private_endpoint_network_policies_enabled = true
service_endpoints = ["Microsoft.Storage"]
service_delegations = {}
},
    #   used for the private endpoints we will deploy
virtual_network_subnets_002 = {
subnet_name = "endpoints"
address_prefix = "10.0.0.32/27"
private_endpoint_network_policies_enabled = true
service_endpoints = ["Microsoft.Storage"]
service_delegations = {}
},
    # final subnet we are going to need is the one used for the database service:
virtual_network_subnets_003 = {
subnet_name = "database"
address_prefix = "10.0.0.64/27"
private_endpoint_network_policies_enabled = true
service_endpoints = ["Microsoft.Storage"]
service_delegations = {
fs = {
"Microsoft.DBforMySQL/flexibleServers" = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
}
}
},
}
}
# -------------Security rules Vars--------------------

variable "network_trusted_ips" {
description = "Optional list if IP addresses which need access, your current IP will be added automatically"
type = list(any)
default = [
]
}

variable "subnet_for_vms" {
description = "Reference to put the virtual machines in"
default = "virtual_network_subnets_001"
}
variable "subnet_for_endpoints" {
description = "Reference to put the private endpoints in"
default = "virtual_network_subnets_002"
}
variable "subnet_for_database" {
description = "Reference to put the database in"
default = "virtual_network_subnets_003"
}


#----------storage vars---------------------
variable "sa_account_tier" {
    description = "sa_account_tier"
    default = "standard"

}
variable "sa_account_replication_type" {
    description = "sa_account_replication_type"
    default = "LRS"

}
variable "sa_network_default_action"{
description = "Specifies the default action of allow or deny when no other rules match. Valid options are Deny or Allow."
default = "Allow"

}
variable "sa_network_bypass"{
description = "Specifies whether traffic is bypassed for Logging/Metrics/AzureServices. Valid options are any combination of Logging, Metrics, AzureServices, or None."
default = "Logging"

}
variable "nfs_share_quota"{
description = " The maximum size of the share, in gigabytes."
default = "50"

}
variable "nfs_enbled_protocol"{
description = "The protocol used for the share. Possible values are SMB and NFS"
default = "NFS"

}
#----------Database vars---------------------
