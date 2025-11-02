data "azurerm_client_config" "current" {}

##############################################################################
# Create Managed k8s cluster
##############################################################################

# add cluster principal id to the vnet to managed ip allocation
resource "azurerm_role_assignment" "vnet_network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = var.managedid_principal_id
}

# add reader to the main as the cluster is in a different RG
resource "azurerm_role_assignment" "vnet_network_reader" {
  scope                = var.vnet_id
  role_definition_name = "Reader"
  principal_id         = var.managedid_principal_id
}


resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.resource_prefix}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.resource_prefix}-aks-dns"
  kubernetes_version  = var.k8s_version

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.admin_ssh_pub_key
    }
  }

  #node_resource_group = "${azurerm_resource_group.env_rg.name}_MC_${azurerm_resource_group.env_rg.location}"
  sku_tier = "Standard"

  # We are removing OIDC as it forces federation
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  private_cluster_enabled = var.aks_private_cluster_enabled

  api_server_access_profile {
    vnet_integration_enabled = true
    subnet_id                = var.aks_api_subnet_id
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.managedid_object_id]
  }

  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id      = var.audit_events_log_analytics_workspace_id
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }

  # Enable EntraID Integration
  role_based_access_control_enabled = true
  local_account_disabled            = var.aks_local_account_disabled

    # azure_active_directory_role_based_access_control {
    #   tenant_id              = var.target_tenant_id
    #   admin_group_object_ids = var.entra_admins_group_object_id
    #   azure_rbac_enabled     = true
    #   managed                = true
    # }
## disbaled temoprariliy as the managedid_object_id is not available for the project demonostration. 


  default_node_pool {
    name                         = "systempool"
    vm_size                      = var.aks_nodepool_configuration["systempool"]["vm_size"]
    os_disk_size_gb              = var.aks_nodepool_configuration["systempool"]["os_disk_size_gb"]
    zones                        = var.aks_set_availability_zones
    min_count                    = var.aks_nodepool_configuration["systempool"]["min_count"]
    max_count                    = var.aks_nodepool_configuration["systempool"]["max_count"]
    orchestrator_version         = var.aks_nodepool_configuration["systempool"]["orchestrator_version"]
    os_sku                       = var.aks_nodepool_configuration["systempool"]["os_sku"]
    enable_auto_scaling          = true
    enable_node_public_ip        = false
    vnet_subnet_id               = var.aks_system_subnet_id
    pod_subnet_id                = var.aks_pods_subnet_id
    only_critical_addons_enabled = true
    enable_host_encryption       = var.aks_nodepool_configuration["systempool"]["enable_host_encryption"]
    os_disk_type                 = var.aks_nodepool_configuration["systempool"]["os_disk_type"]
    temporary_name_for_rotation  = "tempsyspool"

    upgrade_settings {
      drain_timeout_in_minutes      = 0
      max_surge                     = "10%"
      node_soak_duration_in_minutes = 0
    }
  }

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  # Upgrade settings

  automatic_channel_upgrade = "patch"

  node_os_channel_upgrade = "SecurityPatch"

  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 8
    day_of_week = "Sunday"
    start_time  = "03:00"
    utc_offset  = "+02:00"

  }

  maintenance_window_node_os {
    frequency  = "Daily"
    interval   = 1
    duration   = 4
    start_time = "03:00"
    utc_offset = "+02:00"

  }

  # Azure policy is forced, changing this will just cause Terraform noise.
  azure_policy_enabled = var.aks_enable_policy

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    dns_service_ip    = "10.131.0.10"
    service_cidr      = "10.131.0.0/16"
    outbound_type  = "loadBalancer"
    network_policy = "azure"
  }

  http_application_routing_enabled = false


  storage_profile {
    blob_driver_enabled = true
  }

 

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,
      microsoft_defender,
    ]
  }

  tags = var.tags
  depends_on = [
    azurerm_role_assignment.vnet_network_contributor,
    azurerm_role_assignment.vnet_network_reader

  ]
}


resource "azurerm_role_assignment" "aks_cluster_admin_role" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_kubernetes_cluster_node_pool" "main" {
  for_each               = local.aks_nodepools
  name                   = each.key
  kubernetes_cluster_id  = azurerm_kubernetes_cluster.main.id
  vm_size                = each.value["vm_size"]
  os_disk_size_gb        = each.value["os_disk_size_gb"]
  os_disk_type           = each.value["os_disk_type"]
  zones                  = var.aks_set_availability_zones
  min_count              = each.value["min_count"]
  max_count              = each.value["max_count"]
  orchestrator_version   = each.value["orchestrator_version"]
  os_sku                 = var.aks_nodepool_configuration["systempool"]["os_sku"]
  mode                   = "User"
  enable_auto_scaling    = true
  enable_node_public_ip  = false
  enable_host_encryption = each.value["enable_host_encryption"]

  vnet_subnet_id = var.aks_user_subnet_id
  pod_subnet_id  = var.aks_pods_subnet_id

  tags = var.tags
  lifecycle {
    ignore_changes = [
      upgrade_settings,
    ]
  }
}


resource "azurerm_role_assignment" "secrets_reader" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_role_assignment" "certificates_reader" {
  scope                = var.keyvault_id
  role_definition_name = "Key Vault Certificate User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_role_assignment" "blob_reader" {
  scope                = var.keyvault_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity.0.object_id
}

resource "azurerm_monitor_diagnostic_setting" "aks_diag_settings_log_analytics" {
  count                      = var.enable_diagnostic_settings ? 1 : 0
  name                       = "${var.resource_prefix}-aks-diag-settings-la"
  target_resource_id         = azurerm_kubernetes_cluster.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id


  # Enable AKS log categories
  dynamic "enabled_log" {
    for_each = toset([
      "cloud-controller-manager",
      "cluster-autoscaler",
      "csi-azuredisk-controller",
      "csi-azurefile-controller",
      "csi-snapshot-controller",
      "fleet-member-agent",
      "guard",
      "kube-apiserver",
      "kube-audit",
      "kube-audit-admin",
      "kube-controller-manager",
      "kube-scheduler"
    ])
    content {
      category = enabled_log.value
    }
  }

  # Enable AKS metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}

resource "azurerm_monitor_diagnostic_setting" "aks_diag_settings_archive" {
  count              = var.enable_diagnostic_settings ? 1 : 0
  name               = "${var.resource_prefix}-aks-diag-settings-archive"
  target_resource_id = azurerm_kubernetes_cluster.main.id
  storage_account_id = var.storage_account_id

  # Enable AKS log categories
  dynamic "enabled_log" {
    for_each = toset([
      "cloud-controller-manager",
      "cluster-autoscaler",
      "csi-azuredisk-controller",
      "csi-azurefile-controller",
      "csi-snapshot-controller",
      "fleet-member-agent",
      "guard",
      "kube-apiserver",
      "kube-audit",
      "kube-audit-admin",
      "kube-controller-manager",
      "kube-scheduler"
    ])
    content {
      category = enabled_log.value
    }
  }

  # Enable AKS metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }

  lifecycle {
    ignore_changes = [
      metric
    ]
  }
}


resource "azurerm_resource_policy_assignment" "restrict_root_user" { # for linux container
  name                 = "${var.resource_prefix}-restrict-root-user"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = data.azurerm_policy_definition.restrict_root_user.id

  # The allowed values are Mutate/Disabled
  # 'Mutate' modifies a non-compliant resource to be compliant when creating or updating. 'Disabled' turns off the policy.

  parameters = <<PARAMS
{
  "effect": {
    "value": "Mutate"
  },
  "excludedNamespaces": {
    "value": ["kube-system","gatekeeper-system","azure-arc"]
  }
}
PARAMS

}
resource "azurerm_resource_policy_assignment" "restrict_administrator_user" { # for windows container
  name                 = "${var.resource_prefix}-restrict-administrator-user"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = data.azurerm_policy_definition.restrict_administrator_user.id

  # The allowed values are 	Audit/Deny/Disabled
  # 'Audit' allows a non-compliant resource to be created, but flags it as non-compliant. 'Deny' blocks the resource creation. 'Disable' turns off the policy.

  parameters = <<PARAMS
{
  "effect": {
    "value": "Deny"
  },
  "excludedNamespaces": {
    "value": ["kube-system","gatekeeper-system","azure-arc","azure-extensions-usage-system"]
  }
}
PARAMS

}

resource "azurerm_resource_policy_assignment" "allowed_container_registry" {
  name                 = "${var.resource_prefix}-allowed-container-registry"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = data.azurerm_policy_definition.allowed_container_registry.id

  # The allowed values are 	Audit/Deny/Disabled
  # 'Audit' allows a non-compliant resource to be created, but flags it as non-compliant. 'Deny' blocks the resource creation. 'Disable' turns off the policy.

  parameters = jsonencode({
    "effect" = {
      "value" = "Deny"
    },
    "excludedNamespaces" = {
      "value" = ["kube-system", "gatekeeper-system", "azure-arc", "azure-extensions-usage-system"]
    },
    "allowedContainerImagesRegex" = {
      "value" = length(compact(var.allowed_registries)) > 0 ? "^(${join("|", var.allowed_registries)})(/.*)?$" : ""
    }
  })

}

resource "azurerm_policy_definition" "main" {
  name         = "${var.resource_prefix}-ensure-aks-container-memory-limits"
  policy_type  = "Custom"
  mode         = "Microsoft.Kubernetes.Data"
  display_name = "${var.resource_prefix}-Ensure that the container cannot run without applying memory limits"
  description  = "Ensures that Kubernetes containers have memory limits set, while allowing exclusions based on namespace"

  metadata = <<METADATA
  {
    "category": "Kubernetes"
  }
  METADATA

  policy_rule = <<POLICY_RULE
  {
    "if": {
      "field": "type",
      "equals": "Microsoft.ContainerService/managedClusters"
    },
    "then": {
      "effect": "audit",
      "details": {
        "apiGroups": [""],
        "kinds": ["Pod"],
        "templateInfo": {
          "sourceType": "Base64Encoded",
          "content": "${base64encode(file("${path.module}/policies/memory_limits_template.yaml"))}"
        },
        "values": {
          "exemptImages": [],
          "excludedNamespaces": ["kube-system","gatekeeper-system","azure-arc","azure-extensions-usage-system"]
        }
      }
    }
  }
  POLICY_RULE
}


resource "azurerm_resource_policy_assignment" "aks_memory_limit_assignment" {
  name                 = "${var.resource_prefix}-ensure-aks-container-memory-limits"
  resource_id          = azurerm_kubernetes_cluster.main.id
  policy_definition_id = azurerm_policy_definition.main.id
  display_name         = "${var.resource_prefix}-Ensure that the container cannot run without applying memory limits"
  description          = "Ensures that Kubernetes containers running in AKS have memory limits set"

  parameters = <<PARAMETERS
  {}
  PARAMETERS
}