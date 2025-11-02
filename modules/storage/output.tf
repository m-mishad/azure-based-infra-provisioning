output "primary_connection_string" {
  value       = azurerm_storage_account.storage_account.primary_connection_string
  description = "PCS to connect to the storage account"
}

output "primary_access_key" {
  value       = azurerm_storage_account.storage_account.primary_access_key
  description = "PAK to connect to the storage account"
}

output "storage_account_name" {
  value       = azurerm_storage_account.storage_account.name
  description = "Name of the regional storage account"
}

output "storage_account_id" {
  value       = azurerm_storage_account.storage_account.id
  description = "ID of the regional storage account"
}
