resource "azurerm_storage_account" "storage_account" {
  # Storage Account name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  name                            = replace("${var.resource_prefix}sacloudenv", "-", "")
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  # Enable Shared Key authorization
  shared_access_key_enabled = true

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
    virtual_network_subnet_ids = [
 
      var.regional_pods_id
    ]
  }

  lifecycle {
    ignore_changes = [
      network_rules
    ]
  }

  tags = var.tags

}

resource "azurerm_management_lock" "main" {
  count      = var.enable_prevent_delete_lock ? 1 : 0
  name       = "storage-account-delete-lock"
  lock_level = "CanNotDelete"
  scope      = azurerm_storage_account.storage_account.id

}

resource "azurerm_role_assignment" "current_blob_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.principal_id
}

resource "azurerm_role_assignment" "aks_blob_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.aks_principal_id
}

resource "azurerm_role_assignment" "current_file_data_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.principal_id
}

resource "azurerm_role_assignment" "aks_file_data_contributor" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = var.aks_principal_id
}
resource "azurerm_role_definition" "azurefile_share_reader" {
  name  = "afs-${azurerm_storage_account.storage_account.name}"
  scope = azurerm_storage_account.storage_account.id

  permissions {
    actions     = ["Microsoft.Storage/storageAccounts/fileServices/shares/read", "Microsoft.Storage/storageAccounts/fileServices/shares/write", "Microsoft.Storage/storageAccounts/fileServices/shares/delete", "Microsoft.Storage/storageAccounts/listKeys/action", "Microsoft.Storage/operations/read"]
    not_actions = []
  }

  assignable_scopes = [
    azurerm_storage_account.storage_account.id,
  ]
}

resource "azurerm_role_assignment" "aks_file_share_reader" {
  scope              = azurerm_storage_account.storage_account.id
  role_definition_id = azurerm_role_definition.azurefile_share_reader.role_definition_resource_id
  principal_id       = var.aks_principal_id
}

resource "azurerm_private_dns_zone" "regional_storage_account_private_dns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "sa_dns_netlink" {
  name                  = "${var.resource_prefix}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.regional_storage_account_private_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "blob_private_endpoint" {
  name                = "${var.resource_prefix}-blob-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.privatelinks_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "regional-storage-account-private-endpoint"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "regional-storage-account-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.regional_storage_account_private_dns.id]
  }
}

resource "azurerm_private_dns_zone" "regional_file_share_private_dns" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_private_dns_zone_virtual_network_link" "fs_dns_netlink" {
  name                  = "${var.resource_prefix}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.regional_file_share_private_dns.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "file_share_private_endpoint" {
  name                = "${var.resource_prefix}-file-share-pep"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.privatelinks_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "regional-file-share-private-endpoint"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
  private_dns_zone_group {
    name                 = "regional-file-share-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.regional_file_share_private_dns.id]
  }
}


resource "azurerm_monitor_diagnostic_setting" "sa_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-archive"
  target_resource_id = azurerm_storage_account.storage_account.id
  storage_account_id = azurerm_storage_account.storage_account.id


  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}


resource "azurerm_monitor_diagnostic_setting" "la_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-log_analytics"
  target_resource_id         = azurerm_storage_account.storage_account.id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  # log_analytics_destination_type = "AzureDiagnostics"


  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "blob_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-archive"
  target_resource_id = "${azurerm_storage_account.storage_account.id}/blobServices/default"
  storage_account_id = azurerm_storage_account.storage_account.id
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "blob_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-log_analytics"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "file_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-archive"
  target_resource_id = "${azurerm_storage_account.storage_account.id}/fileServices/default"
  storage_account_id = azurerm_storage_account.storage_account.id
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "file_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-log_analytics"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/fileServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
  # log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "table_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-archive"
  target_resource_id = "${azurerm_storage_account.storage_account.id}/tableServices/default"
  storage_account_id = azurerm_storage_account.storage_account.id
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "table_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-log_analytics"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/tableServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id


  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }

}

resource "azurerm_monitor_diagnostic_setting" "queue_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-archive"
  target_resource_id = "${azurerm_storage_account.storage_account.id}/queueServices/default"
  storage_account_id = azurerm_storage_account.storage_account.id
  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "queue_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-log_analytics"
  target_resource_id         = "${azurerm_storage_account.storage_account.id}/queueServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id
 

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_log {
    category = "StorageWrite"
  }

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }

}