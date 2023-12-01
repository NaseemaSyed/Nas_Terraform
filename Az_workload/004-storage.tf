
resource "azurecaf_name" "sa" {
name = var.name
resource_type = "azurerm_storage_account"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "azurecaf_name" "sa_endpoint" {
name = var.name
resource_type = "azurerm_storage_account"
suffixes = [var.environment_type, module.azure_region.location_short]
clean_input= true
}

resource "azurerm_storage_account" "sa"{
    name                     = azurecaf_name.sa.result
  resource_group_name = azurerm_resource_group.resource_group.name
  location = azurerm_resource_group.resource_group.location
  account_tier             = var.sa_account_tier
  account_replication_type = var.sa_account_replication_type

}


resource "azurerm_storage_account_network_rules" "sa" {
storage_account_id = azurerm_storage_account.sa.id
default_action = var.sa_network_default_action
ip_rules = setunion(var.network_trusted_ips,["${jsondecode(data.http.current_ip.response_body).ip}"])
bypass = var.sa_network_bypass
virtual_network_subnet_ids = [
for subnet_id in azurerm_subnet.vnet_subnets :
subnet_id.id
]
}

resource "azurerm_storage_share" "nfs_share" {
name = replace(var.name, "-", "")
storage_account_name = azurerm_storage_account.sa.name
quota = var.nfs_share_quota
enabled_protocol = var.nfs_enbled_protocol
depends_on = [
azurerm_storage_account_network_rules.sa
]
}