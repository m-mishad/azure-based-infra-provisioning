output "fqdn" {
  value       = azurerm_postgresql_flexible_server.main.fqdn
  description = "Postgres FQDN"
}