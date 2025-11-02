# Policy initiative "Enable allLogs category group resource logging for supported resources to Log Analytics" assignment
resource "azurerm_resource_group_policy_assignment" "diagnostic_settings_to_la" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  name                 = "${var.resource_prefix}-enable-diagnostic-settings-assignment-la"
  display_name         = "${var.resource_prefix}-Enable diagnostic settings for supported resources to Log Analytics workspace"
  resource_group_id    = var.resource_group_id
  location             = var.location
  policy_definition_id = data.azurerm_policy_set_definition.diagnostic_settings_to_la.id
  description          = "Assigns the initiative to enable allLogs category group logging for supported resources."


  parameters = jsonencode({
    "logAnalytics" = {
      "value" = "${var.log_analytics_workspace_id}"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "diag_settings_to_la_la_contributor" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  principal_id         = azurerm_resource_group_policy_assignment.diagnostic_settings_to_la[0].identity[0].principal_id
  role_definition_name = "Log Analytics Contributor"
  scope                = "/subscriptions/${var.target_subscription_id}/resourceGroups/${var.resource_group_name}"
}

# Policy initiative "Enable allLogs category group resource logging for supported resources to storage" assignment

resource "azurerm_resource_group_policy_assignment" "diagnostic_settings_to_sa" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  name                 = "${var.resource_prefix}-enable-diagnostic-settings-assignment-sa"
  display_name         = "${var.resource_prefix}-Enable diagnostic settings for supported resources to Storage account"
  resource_group_id    = var.resource_group_id
  location             = var.location
  policy_definition_id = data.azurerm_policy_set_definition.diagnostic_settings_to_sa.id
  description          = "Assigns the initiative to enable allLogs category group logging to Storage for supported resources."


  parameters = jsonencode({
    "storageAccount" = {
      "value" = "${var.storage_account_id}"
    },
    "resourceLocation" = {
      "value" = "${var.location}"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "diag_settings_to_sa_la_contributor" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  principal_id         = azurerm_resource_group_policy_assignment.diagnostic_settings_to_sa[0].identity[0].principal_id
  role_definition_name = "Log Analytics Contributor"
  scope                = "/subscriptions/${var.target_subscription_id}/resourceGroups/${var.resource_group_name}"
}


# Custom Policy definition for NIC

resource "azurerm_policy_definition" "network_interface_diag_settings" {
  count        = var.enable_diagnostic_settings ? 1 : 0
  name         = "${var.resource_prefix}-deploy-diag-set-for-nic"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "${var.resource_prefix}-Deploy Diagnostic Settings for Network Interfaces"
  description  = "Deploys the diagnostic settings for Network Interfaces to stream to a Log Analytics workspace & storage account when any Network Interfaces which is missing this diagnostic settings is created or updated. This policy is superseded by built-in initiative https://www.azadvertizer.net/azpolicyinitiativesadvertizer/0884adba-2312-4468-abeb-5422caed1038.html."

  parameters = <<PARAMETERS
{
  "logAnalytics": {
    "type": "String",
    "metadata": {
      "displayName": "Log Analytics workspace",
      "description": "Select Log Analytics workspace from dropdown list.",
      "strongType": "omsWorkspace"
    }
  },
  "storageAccount": {
    "type": "String",
    "metadata": {
      "displayName": "Storage Account",
      "description": "Select Storage Account to store logs.",
      "assignPermissions": true
    }
  },
  "effect": {
    "type": "String",
    "defaultValue": "DeployIfNotExists",
    "allowedValues": ["DeployIfNotExists", "Disabled"],
    "metadata": {
      "displayName": "Effect",
      "description": "Enable or disable the execution of the policy"
    }
  },
  "profileName": {
    "type": "String",
    "defaultValue": "setbypolicy",
    "metadata": {
      "displayName": "Profile name",
      "description": "The diagnostic settings profile name"
    }
  },
  "metricsEnabled": {
    "type": "String",
    "defaultValue": "True",
    "allowedValues": ["True", "False"],
    "metadata": {
      "displayName": "Enable metrics",
      "description": "Whether to enable metrics stream to the Log Analytics workspace"
    }
  }
}
PARAMETERS

  policy_rule = <<RULE
{
  "if": {
    "field": "type",
    "equals": "Microsoft.Network/networkInterfaces"
  },
  "then": {
    "effect": "[parameters('effect')]",
    "details": {
      "type": "Microsoft.Insights/diagnosticSettings",
      "name": "[parameters('profileName')]",
      "existenceCondition": {
        "allOf": [
          { "field": "Microsoft.Insights/diagnosticSettings/metrics.enabled", "equals": "true" },
          { "field": "Microsoft.Insights/diagnosticSettings/workspaceId", "equals": "[parameters('logAnalytics')]" },
          { "field": "Microsoft.Insights/diagnosticSettings/storageAccountId", "equals": "[parameters('storageAccount')]" }
        ]
      },
      "roleDefinitionIds": [
        "/providers/microsoft.authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa",
        "/providers/microsoft.authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
      ],
      "deployment": {
        "properties": {
          "mode": "Incremental",
          "template": {
            "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
            "contentVersion": "1.0.0.0",
            "parameters": {
              "resourceName": { "type": "String" },
              "logAnalytics": { "type": "String" },
              "storageAccount": { "type": "String" },
              "location": { "type": "String" },
              "profileName": { "type": "String" },
              "metricsEnabled": { "type": "String" }
            },
            "resources": [
              {
                "type": "Microsoft.Network/networkInterfaces/providers/diagnosticSettings",
                "apiVersion": "2017-05-01-preview",
                "name": "[concat(parameters('resourceName'), '/', 'Microsoft.Insights/', parameters('profileName'))]",
                "location": "[parameters('location')]",
                "properties": {
                  "workspaceId": "[parameters('logAnalytics')]",
                  "storageAccountId": "[parameters('storageAccount')]",
                  "metrics": [
                    {
                      "category": "AllMetrics",
                      "enabled": "[parameters('metricsEnabled')]",
                      "retentionPolicy": { "enabled": false, "days": 0 }
                    }
                  ]
                }
              }
            ]
          },
          "parameters": {
            "logAnalytics": { "value": "[parameters('logAnalytics')]" },
            "storageAccount": { "value": "[parameters('storageAccount')]" },
            "location": { "value": "[field('location')]" },
            "resourceName": { "value": "[field('name')]" },
            "profileName": { "value": "[parameters('profileName')]" },
            "metricsEnabled": { "value": "[parameters('metricsEnabled')]" }
          }
        }
      }
    }
  }
}
RULE
}

# Policy assignment for NIC

resource "azurerm_resource_group_policy_assignment" "diagnostic_settings_to_sa_la" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  name                 = "${var.resource_prefix}-enable-diagnostic-settings-assignment"
  display_name         = "${var.resource_prefix}-Enable diagnostic settings for NIC"
  resource_group_id    = var.resource_group_id
  location             = var.location
  policy_definition_id = azurerm_policy_definition.network_interface_diag_settings[0].id
  description          = "Assigns the policy to enable allLogs category group logging for NIC."

  parameters = jsonencode({
    "logAnalytics" = {
      "value" = "${var.log_analytics_workspace_id}"
    },
    "storageAccount" = {
      "value" = "${var.storage_account_id}"
    }
  })

  identity {
    type = "SystemAssigned"
  }
}

# Role assignmnet for NIC
resource "azurerm_role_assignment" "nic_la_contributor" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  principal_id         = azurerm_resource_group_policy_assignment.diagnostic_settings_to_sa_la[0].identity[0].principal_id
  role_definition_name = "Log Analytics Contributor"
  scope                = "/subscriptions/${var.target_subscription_id}/resourceGroups/${var.resource_group_name}"
}

resource "azurerm_role_assignment" "nic_mon_contributor" {
  count                = var.enable_diagnostic_settings ? 1 : 0
  principal_id         = azurerm_resource_group_policy_assignment.diagnostic_settings_to_sa_la[0].identity[0].principal_id
  role_definition_name = "Monitoring Contributor"
  scope                = "/subscriptions/${var.target_subscription_id}/resourceGroups/${var.resource_group_name}"
}