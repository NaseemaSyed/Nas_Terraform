resource "azurecaf_name" "admin_vm" {
name = var.name
resource_type = "azurerm_network_interface"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}
resource "azurecaf_name" "admin_vm_nic"{
name = var.name
resource_type = "azurerm_linux_virtual_machine"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "random_password" "wordpress_admin_password"{
  length = 9
special = true
}

resource "random_password" "vm_admin_password"{
  length = 9
special = false
 }



resource "azurerm_network_interface" "admin_vm_nic"{
     name                = azurecaf_name.admin_vm_nic.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.var.subnet_for_vms.id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_linux_virtual_machine" "admin_vm"{ 
name                = azurecaf_name.admin_vm_.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
size                = "Standard_F2"
  admin_username      = "vm_admin"
  admin_password =  random_password.vm_admin_password.result
  network_interface_ids = [
    azurerm_network_interface.admin_vm_nic.id,
  ]
//
//  admin_ssh_key {
 //   username   = "adminuser"
 ///   public_key = file("~/.ssh/id_rsa.pub")
  //}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
