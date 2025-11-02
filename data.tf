data "http" "agent_ip" {
  url = "https://checkip.amazonaws.com"
}

data "azurerm_client_config" "current" {}