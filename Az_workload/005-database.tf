resource "azurecaf_name" "mysql_flexible_server" {
  name          = "mysql"
  resource_type = "azurerm_mysql_flexible_server"
  suffixes      = [var.name, var.environment_type, module.azure_region.location_short]
  clean_input   = true
}
resource "random_password" "database_admin_password" {
  length  = 9
  special = false
}


#the private DNS zone we will use for our Azure MySQL Flexible Server
resource "azurerm_private_dns_zone" "mysql_flexible_server" {
  name                = azurecaf_name.mysql_flexible_server.result
  resource_group_name = azurerm_resource_group.resource_group.name

}
# registers the private DNS with our Virtual Network
resource "azurerm_private_dns_zone_virtual_network_link" "mysql_flexible_server" {
  name                  = azurecaf_name.mysql_flexible_server.result
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.mysql_flexible_server.name
  virtual_network_id    = azurerm_virtual_network.vnet.id

}
# we use depends_on here to ensure that the DNS zone is registered with the Virtual Network;
resource "azurerm_mysql_flexible_server" "mysql_flexible_server" {
  name                = azurecaf_name.mysql_flexible_server.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  administrator_login    = "database_admin_TF"
  administrator_password = random_password.database_admin_password.result
  sku_name               = "GP_Standard_D2ds_v4"
}


resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  name                = azurecaf_name.mysql_flexible_server.result
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mysql_flexible_server.mysql_flexible_server.name
  value               = "600"
}

#creates a database hosted on the Azure MySQL Flexible Server
resource "azurerm_mysql_flexible_database" "wordpress_database" {
  name                = azurecaf_name.mysql_flexible_server.result
  resource_group_name = azurerm_resource_group.resource_group.name
  server_name         = azurerm_mysql_flexible_server.mysql_flexible_server.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"

}