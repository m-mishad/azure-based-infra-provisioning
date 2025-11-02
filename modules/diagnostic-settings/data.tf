data "azurerm_policy_set_definition" "diagnostic_settings_to_la" {
  display_name = "Enable allLogs category group resource logging for supported resources to Log Analytics"
}

data "azurerm_policy_set_definition" "diagnostic_settings_to_sa" {
  display_name = "Enable allLogs category group resource logging for supported resources to storage"
}