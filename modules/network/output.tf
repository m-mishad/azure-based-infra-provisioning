output "vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = ""
}

output "postgres_subnet_id" {
  value       = azurerm_subnet.postgres_subnet.id
  description = ""
}

output "vnet_name" {
  value       = azurerm_virtual_network.main.name
  description = ""
}


output "private_dns_zone_id" {
  value       = length(azurerm_private_dns_zone.main) > 0 ? azurerm_private_dns_zone.main[0].id : null
  description = "The ID of the private DNS zone for PostgreSQL"
}

output "aks_api_subnet_id" {
  value       = azurerm_subnet.aks_api.id
  description = ""
}

output "aks_pods_subnet_id" {
  value       = azurerm_subnet.aks_pods.id
  description = "ID of the AKS pod subnet"
}

output "aks_system_subnet_id" {
  value       = azurerm_subnet.aks_systempool.id
  description = "ID of the AKS system subnet"
}

output "aks_user_subnet_id" {
  value       = azurerm_subnet.aks_userpool.id
  description = ""
}

output "nsg_ids" {
  description = "A map of all NSG IDs"
  value = {
    aks_pods            = azurerm_network_security_group.aks_pods.id
    aks_systempool      = azurerm_network_security_group.aks_systempool.id
    aks_userpool        = azurerm_network_security_group.aks_userpool.id
    aks_api             = azurerm_network_security_group.aks_api.id
    postgres            = azurerm_network_security_group.postgres.id
    private_link        = azurerm_network_security_group.private_link.id
  }
}

output "privatelinks_subnet_id" {
  value       = azurerm_subnet.private_link.id
  description = ""
}

output "appgw_subnet_id" {
  value       = azurerm_subnet.application_gateway.id
  description = ""
}