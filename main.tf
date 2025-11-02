terraform {
  required_version = "> 1.11.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~>3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.113.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
  }
 
  backend "azurerm" { 

  }
}

provider "azurerm" {
  features {}
  tenant_id       = var.target_tenant_id
  subscription_id                 = var.target_subscription_id
}

resource "azurerm_resource_group" "main" {
  name     = local.rg_name
  location = var.location
  tags     = local.tags
}

# Key used to deploy the environment
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create user managed identity
resource "azurerm_user_assigned_identity" "main" {
  name                = "${azurerm_resource_group.main.name}-uaid"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags

  depends_on = [azurerm_resource_group.main]
}


moved {
  from = azurerm_log_analytics_workspace.main
  to   = azurerm_log_analytics_workspace.main[0]
}

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.audit_events_log_analytics_workspace_id == "" ? 1 : 0
  name                = "${local.resource_prefix}-log"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30 
  tags                = local.tags

  depends_on = [azurerm_resource_group.main]
}

# Enabling diagnostic setting and sending logs to Log analytics workspace
resource "azurerm_monitor_diagnostic_setting" "log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${local.resource_prefix}-log_analytics"
  target_resource_id         = azurerm_log_analytics_workspace.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id

  metric {
    category = "AllMetrics"
  }
}

# Enabling diagnostic setting and sending logs to storage account

resource "azurerm_monitor_diagnostic_setting" "archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${local.resource_prefix}-archive"
  target_resource_id = azurerm_log_analytics_workspace.main[0].id
  storage_account_id = module.audit_log_storage.storage_account.id


  metric {
    category = "AllMetrics"
  }
}

module "network" {
  source                     = "./modules/network"
  short_resource_name_prefix = local.short_resource_name_prefix
  tags                       = local.tags
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  azure_deploy_postgres      = var.azure_deploy_postgres
  virtual_network_name       = local.subnet_name
  subnet_name                = local.vnet_name
  depends_on            = [module.diagnostic-settings]
}

module "keyvault" {
  source                     = "./modules/keyvault"
  short_resource_name_prefix = local.short_resource_name_prefix
  tags                       = local.tags
  resource_prefix                           = local.resource_prefix
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  target_tenant_id           = var.target_tenant_id
  kv_name                    = local.kv_name
  vnet_id                    = module.network.vnet_id
  privatelinks_subnet_id                    = module.network.privatelinks_subnet_id
  storage_account_primary_connection_string = module.storage.primary_connection_string
  pods_id                    = module.network.aks_pods_subnet_id
  whitelist_ip               = data.http.agent_ip.response_body
  managedid_object_id        = azurerm_user_assigned_identity.main.principal_id
  runner_object_id           = data.azurerm_client_config.current.object_id
  enable_prevent_delete_lock = local.enable_prevent_delete_lock
  depends_on                 = [module.network, module.diagnostic-settings]
}



module "postgres" {
  source                     = "./modules/postgres"
  for_each                   = var.azure_deploy_postgres == true ? var.postgres_config : {}
  tags                       = local.tags
  resource_prefix            = local.resource_prefix
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  admin_login                = var.admin_username
  admin_password             = var.admin_password
  enable_prevent_delete_lock = local.enable_prevent_delete_lock
  instance_key               = each.key
  sku_name                   = each.value.postgres_sku
  pg_version                 = each.value.postgres_version
  storage_mb                 = each.value.storage_size
  delegated_subnet_id        = module.network.postgres_subnet_id
  priv_dns_zone_id           = module.network.private_dns_zone_id
  vnet_id                    = module.network.vnet_id
  short_resource_name_prefix = join("-", [local.short_resource_name_prefix, each.key])
  depends_on                 = [module.network, module.diagnostic-settings]
}

module "audit_log_storage" {
  source                     = "./modules/audit-log-storage"
  tags                       = local.tags
  resource_group             = azurerm_resource_group.main
  log_analytics_workspace_id = local.audit_events_log_analytics_workspace_id
  enable_prevent_delete_lock = local.enable_prevent_delete_lock
  enable_diagnostic_settings = var.enable_diagnostic_settings
  resource_prefix            = local.resource_prefix
}

module "aks" {
  source               = "./modules/aks"
  tags                 = local.tags
  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  aks_api_subnet_id    = module.network.aks_api_subnet_id
  aks_pods_subnet_id   = module.network.aks_pods_subnet_id
  aks_system_subnet_id = module.network.aks_system_subnet_id
  aks_user_subnet_id   = module.network.aks_user_subnet_id
  keyvault_id                             = module.keyvault.id
  vnet_id                                 = module.network.vnet_id
  managedid_principal_id                  = azurerm_user_assigned_identity.main.principal_id
  managedid_object_id                     = azurerm_user_assigned_identity.main.id
  admin_username                          = var.admin_username
  admin_ssh_pub_key                       = tls_private_key.main.public_key_openssh
  k8s_version                             = var.k8s_version
  aks_private_cluster_enabled             = var.aks_private_cluster_enabled
  aks_enable_policy                       = var.aks_enable_policy
  aks_set_availability_zones              = var.aks_set_availability_zones
  aks_nodepool_configuration              = var.aks_nodepool_configuration
  audit_events_log_analytics_workspace_id = local.audit_events_log_analytics_workspace_id
  resource_prefix                         = local.resource_prefix
  aks_local_account_disabled              = var.aks_local_account_disabled
  allowed_registries                = var.allowed_registries
  log_analytics_workspace_id              = local.audit_events_log_analytics_workspace_id
  storage_account_id                      = module.audit_log_storage.storage_account.id
  enable_diagnostic_settings              = var.enable_diagnostic_settings
  depends_on                 = [module.diagnostic-settings]
}

module "diagnostic-settings" {
  source                     = "./modules/diagnostic-settings"
  enable_diagnostic_settings = var.enable_diagnostic_settings
  resource_prefix            = local.resource_prefix
  log_analytics_workspace_id = local.audit_events_log_analytics_workspace_id
  storage_account_id         = module.audit_log_storage.storage_account.id
  resource_group_name        = azurerm_resource_group.main.name
  target_subscription_id     = var.target_subscription_id
  resource_group_id          = azurerm_resource_group.main.id
  location                   = azurerm_resource_group.main.location
}

# module "network-watcher-flow-log" {
#   count                      = var.enable_flow_logs ? 1 : 0
#   source                     = "./modules/network-watcher-flow-log"
#   enable_flow_logs           = var.enable_flow_logs
#   enable_diagnostic_settings = var.enable_diagnostic_settings
#   enable_prevent_delete_lock = local.enable_prevent_delete_lock
#   resource_prefix            = local.resource_prefix
#   tags                       = local.tags
#   location                   = azurerm_resource_group.main.location
#   resource_group_name        = azurerm_resource_group.main.name
#   storage_account_id         = module.audit_log_storage.storage_account.id
#   log_analytics_workspace_id = local.audit_events_log_analytics_workspace_id
#   nsg_ids                    = module.network.nsg_ids
#   depends_on                 = [module.network, module.diagnostic-settings]
# }

module "storage" {
  source = "./modules/storage"
  tags                       = local.tags
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  regional_pods_id           = module.network.aks_pods_subnet_id
  principal_id               = data.azurerm_client_config.current.object_id
  aks_principal_id           = azurerm_user_assigned_identity.main.principal_id
  vnet_id                    = module.network.vnet_id
  privatelinks_subnet_id     = module.network.privatelinks_subnet_id
  enable_prevent_delete_lock = local.enable_prevent_delete_lock
  enable_diagnostic_settings = var.enable_diagnostic_settings
  depends_on                 = [module.network, module.diagnostic-settings]
  resource_prefix            = local.resource_prefix
}

module "appgw" {
  source                                  = "./modules/appgw"
  tags                                    = local.tags
  resource_group_name                     = azurerm_resource_group.main.name
  location                                = azurerm_resource_group.main.location
  managedid_object_id                     = azurerm_user_assigned_identity.main.id
  aks_principal_id                        = azurerm_user_assigned_identity.main.principal_id
  appgw_subnet_id                         = module.network.appgw_subnet_id
  resource_prefix                         = local.resource_prefix
  enable_prevent_delete_lock              = local.enable_prevent_delete_lock
  depends_on                              = [module.network, module.diagnostic-settings]
}

