output "name" {
  value       = azurerm_key_vault.main.name
  description = "Name of the regional Key vault resource"
}

output "id" {
  value       = azurerm_key_vault.main.id
  description = "ID of the regional Key vault resource"
}