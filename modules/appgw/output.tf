output "main" {
  value = azurerm_public_ip.main.ip_address
}

output "azure_appgw_id" {
  value = azurerm_application_gateway.main.id

}
output "azure_appgw_name" {
  value = azurerm_application_gateway.main.name

}