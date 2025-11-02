locals {
  log_lifetime_retention = 180
}

resource "azurerm_storage_account" "main" {
  # Storage Account name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  name                            = replace("${var.resource_prefix}log", "-", "")
  location                        = var.resource_group.location
  resource_group_name             = var.resource_group.name
  account_tier                    = "Standard"
  access_tier                     = "Cool"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"
  tags                            = var.tags
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

resource "azurerm_management_lock" "main" {
  count      = var.enable_prevent_delete_lock ? 1 : 0
  name       = "audit-log-delete-lock"
  lock_level = "CanNotDelete"
  scope      = azurerm_storage_account.main.id
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "delete-logs-after-lifetime-retention"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
      # Applies to all blobs in all containers, no need for a specific container
    }

    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = local.log_lifetime_retention
      }
    }
  }
}

# Enabling diagnostic setting and sending logs to storage account
resource "azurerm_monitor_diagnostic_setting" "sa_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-sa-diag-settings-archive"
  target_resource_id = azurerm_storage_account.main.id
  storage_account_id = azurerm_storage_account.main.id


  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

# Enabling diagnostic setting and sending logs to Log analytics workspace
resource "azurerm_monitor_diagnostic_setting" "sa_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-sa-diag-settings-la"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  metric {
    category = "AllMetrics"
  }
  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}


# Enabling diagnostic setting and sending logs to storage account

resource "azurerm_monitor_diagnostic_setting" "blob_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-blob-diag-settings-archive"
  target_resource_id = "${azurerm_storage_account.main.id}/blobServices/default"
  storage_account_id = azurerm_storage_account.main.id
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


# Enabling diagnostic setting and sending logs to Log analytics workspace

resource "azurerm_monitor_diagnostic_setting" "blob_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-blob-diag-settings-la"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
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



# Enabling diagnostic setting and sending logs to storage account
resource "azurerm_monitor_diagnostic_setting" "file_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-file-diag-settings-archive"
  target_resource_id = "${azurerm_storage_account.main.id}/fileServices/default"
  storage_account_id = azurerm_storage_account.main.id
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


# Enabling diagnostic setting and sending logs to Log analytics workspace

resource "azurerm_monitor_diagnostic_setting" "file_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-file-diag-settings-la"
  target_resource_id         = "${azurerm_storage_account.main.id}/fileServices/default"
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



# Enabling diagnostic setting and sending logs to storage account

resource "azurerm_monitor_diagnostic_setting" "table_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-table-diag-archive"
  target_resource_id = "${azurerm_storage_account.main.id}/tableServices/default"
  storage_account_id = azurerm_storage_account.main.id
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


# Enabling diagnostic setting and sending logs to Log analytics workspace

resource "azurerm_monitor_diagnostic_setting" "table_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-table-diag-settings-la"
  target_resource_id         = "${azurerm_storage_account.main.id}/tableServices/default"
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

# Enabling diagnostic setting and sending logs to storage account

resource "azurerm_monitor_diagnostic_setting" "queue_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-queue-diag-settings-archive"
  target_resource_id = "${azurerm_storage_account.main.id}/queueServices/default"
  storage_account_id = azurerm_storage_account.main.id
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


# Enabling diagnostic setting and sending logs to Log analytics workspace

resource "azurerm_monitor_diagnostic_setting" "queue_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-queue-diag-settings-la"
  target_resource_id         = "${azurerm_storage_account.main.id}/queueServices/default"
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