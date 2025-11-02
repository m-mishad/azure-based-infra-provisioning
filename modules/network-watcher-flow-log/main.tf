locals {
  log_lifetime_retention = 30
}

resource "azurerm_storage_account" "main" {
  name                            = replace("${var.resource_prefix}sanwflowlog", "-", "")
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  # Enable Shared Key authorization
  shared_access_key_enabled = true
  tags                      = var.tags
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
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
  storage_account_id = var.storage_account_id


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
  storage_account_id = var.storage_account_id
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
  storage_account_id = var.storage_account_id
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
  name               = "${var.resource_prefix}-table-diag-settings-archive"
  target_resource_id = "${azurerm_storage_account.main.id}/tableServices/default"
  storage_account_id = var.storage_account_id
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
  storage_account_id = var.storage_account_id
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

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.resource_prefix}-log-nw-flow-log"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  daily_quota_gb      = 1
  retention_in_days   = local.log_lifetime_retention
  tags                = var.tags

  depends_on = [var.resource_group_name]
}



resource "azurerm_network_watcher_flow_log" "main" {
  for_each             = var.enable_flow_logs ? var.nsg_ids : {}
  name                 = "flowlog-nsg-${each.key}"
  network_watcher_name = "NetworkWatcher_${var.location}"
  resource_group_name  = "NetworkWatcherRG"
  tags                 = var.tags

  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.main.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.main.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.main.location
    workspace_resource_id = azurerm_log_analytics_workspace.main.id
    interval_in_minutes   = 60
  }
}
