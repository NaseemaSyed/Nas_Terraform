resource "azurecaf_name" "virtual_network_subnets" {
for_each = var.vnet_subnets
name = each.value.subnet_name
resource_type = "azurerm_subnet"
suffixes = [var.name, var.environment_type, module.azure_region.location_short]
clean_input = true
}

resource "azurerm_virtual_network" "vnet" {
resource_group_name = azurerm_resource_group.resource_group.name
location = azurerm_resource_group.resource_group.location
name = azurecaf_name.vnet.result
address_space = var.vnet_address_space
tags = var.default_tags
}


resource "azurerm_subnet" "vnet_subnets" {
for_each = var.vnet_subnets
name = azurecaf_name.virtual_network_subnets[each.key].result
resource_group_name = azurerm_resource_group.resource_group.name
virtual_network_name = azurerm_virtual_network.vnet.name
address_prefixes = [each.value.address_prefix]
service_endpoints = try(each.value.service_endpoints, [])
private_endpoint_network_policies_enabled = try(each.value.private_endpoint_network_policies_enabled, [])
dynamic "delegation" {
for_each = each.value.service_delegations
content {
name = delegation.key
dynamic "service_delegation" {
for_each = delegation.value
iterator = item
content {
name = item.key
actions = item.value
}
}
}
}
}

data "http" "current_ip" {
url = "https://api.ipify.org?format=json"
}

resource "azurerm_network_security_group" "nsg"{
    name              = "nsg"
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
}
resource "azurerm_network_security_rule" "AllowHTTP" {
  name                        = "AllowHTTP"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name = azurerm_resource_group.resource_group.name
  network_security_group_name = azurerm_network_security_group.nsg.name

}

resource "azurerm_network_security_rule" "AllowSSH" {
name = "AllowSSH"
description = "Allow SSH"
priority = 150
direction = "Inbound"
access = "Allow"
protocol = "Tcp"
source_address_prefixes = setunion(var.network_trusted_ips,["${jsondecode(data.http.current_ip.response_body).ip}"])   # the built-in setunion function, which merges the content of var.network_trusted_ips– in our case, an empty list – and the JSON returned in the body of the request we made using theHTTP provider
source_port_range = "*"
destination_port_range = "22"
destination_address_prefix = "*"
resource_group_name = azurerm_resource_group.resource_group.name
network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
subnet_id = azurerm_subnet.vnet_subnets["${var.subnet_for_vms}"].id
network_security_group_id = azurerm_network_security_group.nsg.id
}





resource "azurerm_public_ip" "load_balancer" {
  name                = "PublicIPForLB"
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  allocation_method   = "Static"
}

resource "azurerm_lb" "load_balancer" {
  name                = "load_balancer"
  location = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.name.id
  }
}


resource "azurerm_lb_backend_address_pool" "load_balancer" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "http_load_balancer_probe" {
  loadbalancer_id = azurerm_lb.load_balancer.id
  name            = "TCP-test-probe"
  port            = 80
}
resource "azurerm_lb_rule" "http_load_balancer_rule" {
  loadbalancer_id                = azurerm_lb.load_balancer.id
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
}



resource "azurerm_lb_nat_rule" "sshAccess"{
  resource_group_name = azurerm_resource_group.resource_group.name
  loadbalancer_id                = azurerm_lb.name.id
  name                           = "RDPAccess"
  protocol                       = "Tcp"
  frontend_port_start            = 2222
  frontend_port_end              = 2232
  backend_port                   = 22
  backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
  frontend_ip_configuration_name = "PublicIPAddress"
}

