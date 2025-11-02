data "azurerm_policy_definition" "restrict_root_user" {
  display_name = "[Preview]: Prevents containers from being ran as root by setting runAsNotRoot to true."

}

data "azurerm_policy_definition" "restrict_administrator_user" {
  display_name = "Kubernetes cluster Windows containers should not run as ContainerAdministrator"

}

data "azurerm_policy_definition" "allowed_container_registry" {
  display_name = "Kubernetes cluster containers should only use allowed images"

}
