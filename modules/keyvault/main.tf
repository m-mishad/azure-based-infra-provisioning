resource "azurerm_key_vault" "main" {
  name                            = var.kv_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  tenant_id                       = var.target_tenant_id
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  enabled_for_disk_encryption     = true
  sku_name                        = "standard"

  enable_rbac_authorization = true

  # Network access
  public_network_access_enabled = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = ["${chomp(var.whitelist_ip)}/32"]
    virtual_network_subnet_ids = [
      var.pods_id
    ]
  }
  tags = var.tags


}

resource "azurerm_management_lock" "main" {
  count      = var.enable_prevent_delete_lock ? 1 : 0
  name       = "key-vault-delete-lock"
  lock_level = "CanNotDelete"
  scope      = azurerm_key_vault.main.id
}

data "azurerm_client_config" "current" {}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.runner_object_id
}

resource "azurerm_role_assignment" "kv_certificates_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = var.runner_object_id
}

resource "azurerm_role_assignment" "managed_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.managedid_object_id
}

resource "azurerm_role_assignment" "managed_secrets_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.managedid_object_id
}

resource "azurerm_role_assignment" "key_vault_contributor" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Contributor"
  principal_id         = var.managedid_object_id
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                  = "kv-network-link"
  private_dns_zone_name = azurerm_private_dns_zone.main.name
  virtual_network_id    = var.vnet_id
  tags                  = var.tags

  resource_group_name = var.resource_group_name
}

resource "azurerm_private_endpoint" "main" {
  name                = "${var.kv_name}-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.privatelinks_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.kv_name}-pep-con"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "${var.kv_name}-pep-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
  }
}
