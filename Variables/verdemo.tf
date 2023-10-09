terraform {
  required_providers {
    
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
    subscription_id = var.subscription_id
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "nas" {
  name     = "nas-resourcegroupnjs"
  location = var.location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "nas" {
  name                = "nas-network1"
  resource_group_name = azurerm_resource_group.nas.name
  location            = azurerm_resource_group.nas.location
  address_space       = [var.address_space]
}

resource "azurerm_network_security_group" "nas" {
  name                = "nasSecurityGroup1"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name

  security_rule {
    name                       = "TCP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_service_plan" "SP" {
  name                = "api-appserviceplan-B1"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name

 os_type             = "Linux"
  sku_name            = "B1"
  tags = {
    environment = "Dev"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "containerRegistrynjs"
  resource_group_name = azurerm_resource_group.nas.name
  location            = azurerm_resource_group.nas.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = {
    environment = "Dev"
  }
  
  
}