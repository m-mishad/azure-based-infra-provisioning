output "env_cluster_name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = ""
}
output "env_cluster_client_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_certificate
  description = ""
}
output "env_cluster_ca_certificate" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].cluster_ca_certificate
  description = ""
}
output "env_cluster_client_key" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].client_key
  description = ""
}
output "name" {
  value       = azurerm_kubernetes_cluster.main.name
  description = ""
}
output "env_cluster_password" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].password
  description = ""
}
output "env_cluster_username" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].username
  description = ""
}
output "env_cluster_host" {
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  description = ""
}
output "env_cluster_kube_config" {
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  description = ""
}
output "env_cluster_oidc_url" {
  value       = azurerm_kubernetes_cluster.main.oidc_issuer_url
  description = ""
}
output "env_cluster_keyvault_secret_provider_client_id" {
  value       = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
  description = ""
}
output "env_cluster_mc_resource_group" {
  value       = azurerm_kubernetes_cluster.main.node_resource_group
  description = ""
}
output "secret_identity_client_id" {
  value       = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
  description = ""
}
output "kubelet_identity" {
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  description = ""
}
output "node_resource_group" {
  value       = azurerm_kubernetes_cluster.main.node_resource_group
  description = ""
}
output "id" {
  value       = azurerm_kubernetes_cluster.main.id
  description = "ID of the AKS cluster"
}

output "location" {
  value = azurerm_kubernetes_cluster.main.location
}
