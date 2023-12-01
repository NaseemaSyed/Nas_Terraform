terraform {
required_version = ">=1.0"
required_providers {
azurerm = {
source = "hashicorp/azurerm"
version = "~>3.0"
}
azurecaf = {
source = "aztfmod/azurecaf"
}
random = {
source = "hashicorp/random"
}
http = {
source = "hashicorp/http"
}
}
}

provider "azurerm" {
features {}
}

module "azure_region" {
source = "claranet/regions/azurerm"
azure_region = var.location
}

resource "azurecaf_name" "resource_group" {
name = var.name
resource_type = "azurerm_resource_group"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "azurecaf_name" "virtual_network_subnets" {
for_each = var.vnet_subnets
name = each.value.subnet_name
resource_type = "azurerm_subnet"
suffixes = [var.name, var.environment_type, module.azure_region.location_short]
clean_input = true
}