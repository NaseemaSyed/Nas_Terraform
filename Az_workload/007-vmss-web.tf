 generates the name of the Virtual Machine Scale Set.
resource "azurecaf_name" "web_vmss" {
name = var.name
resource_type = "web_vmss"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "azurecaf_name" "web_vmss_nic" {
name = var.name
resource_type = "web_vmss_nic"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "azurerm_network_interface" "web_vmss_nic"{
     name                = azurecaf_name.web_vmss_nic.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.var.subnet_for_vms.id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_linux_virtual_machine_scale_set" "web"{

name                = azurecaf_name.web_vmss_.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
sku                = "Standard_F2"
instances           = var.number_of_web_servers,
  admin_username      = "adminuser"
admin_password = random_password.wordpress_admin_password.result

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "web_vmss_nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.var.subnet_for_vms.id
    }
  }
}

