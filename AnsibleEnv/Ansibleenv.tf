provider "azurerm" {
  subscription_id            = var.subscription_id
  skip_provider_registration = true # This is only required when the User, Service Principal, or Identity running Terraform lacks the permissions to register Azure Resource Providers.
  features {}
}

provider "random" {
  # Configuration options
}

# Create a resource group
resource "azurerm_resource_group" "nas" {
  name     = "${var.prefix}-rgansibleenv"
  location = var.location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "nas" {
  name                = "${var.prefix}-network1"
  resource_group_name = azurerm_resource_group.nas.name
  location            = azurerm_resource_group.nas.location
  address_space       = [var.address_space]
}

resource "azurerm_network_security_group" "nas" {
  name                = "${var.prefix}-SecurityGroup1"
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
  security_rule {
    name                       = "RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "RDP"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Dev"
    source = "terraform"
  }
}
resource "azurerm_subnet" "nas" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.nas.name
  virtual_network_name = azurerm_virtual_network.nas.name
  address_prefixes     = ["10.0.2.0/24"]
}
# Create public IPs
resource "azurerm_public_ip" "linux_public_ip" {
  name                = "LinuxPublicIP"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name
  allocation_method   = "Dynamic"
}
# Create public IPs
resource "azurerm_public_ip" "win_public_ip" {
  name                = "WinPublicIP"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "nas" {
  name                = "${var.prefix}-nic_l"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nas.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.linux_public_ip.id
  }
}

resource "azurerm_network_interface" "nas2" {
  name                = "${var.prefix}-nic_w"
  location            = azurerm_resource_group.nas.location
  resource_group_name = azurerm_resource_group.nas.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nas.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.win_public_ip.id
  }
}
# Create Linux VM
resource "azurerm_linux_virtual_machine" "nas" {
  name                = "${var.prefix}-ubuntu"
  resource_group_name = azurerm_resource_group.nas.name
  location            = azurerm_resource_group.nas.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.nas.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

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
#Create Random password for admin account
resource "random_password" "random_pass" {
  length           = 9
  special          = true
  upper            = true
  override_special = "/@£$"
}
#Create Windows VM
resource "azurerm_windows_virtual_machine" "nas" {
  name                = "${var.prefix}-windows"
  resource_group_name = azurerm_resource_group.nas.name
  location            = azurerm_resource_group.nas.location
  size                = "Standard_B2s"
  admin_username      = var.admin_username
  admin_password      = random_password.random_pass
  network_interface_ids = [
    azurerm_network_interface.nas2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "Windows-10"
    sku       = "21h1-pro"
    version   = "latest"
  }
}
