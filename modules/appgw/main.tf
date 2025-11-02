resource "azurerm_public_ip" "main" {
  name                = "${var.resource_prefix}-agw-ip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.appgw_set_availability_zones
  tags                = var.tags
}

resource "azurerm_management_lock" "main" {
  count      = var.enable_prevent_delete_lock ? 1 : 0
  name       = "agw-delete-lock"
  lock_level = "CanNotDelete"
  scope      = azurerm_public_ip.main.id
#   lifecycle {
#     prevent_destroy = true
#   }
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.resource_prefix}-agw"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags = var.tags

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = var.appgw_subnet_id
  }

  frontend_port {
    name = "frontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGatewayFrontendIP"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  backend_address_pool {
    name = "defaultBackendPool"
  }

  backend_http_settings {
    name                  = "appGatewayBackendHttpSettings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
    request_timeout       = 20
  }

  http_listener {
    name                           = "appGatewayHttpListener"
    frontend_ip_configuration_name = "appGatewayFrontendIP"
    frontend_port_name             = "frontendPort"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "rule1"
    rule_type                  = "Basic"
    http_listener_name         = "appGatewayHttpListener"
    backend_address_pool_name  = "defaultBackendPool"
    backend_http_settings_name = "appGatewayBackendHttpSettings"
    priority                   = 100
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101" # Supports TLS 1.2+
  }
  
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managedid_object_id]
  }
    zones = var.appgw_set_availability_zones
}

resource "azurerm_role_assignment" "aks_agic_contributor" {
  scope                = azurerm_application_gateway.main.id
  role_definition_name = "Contributor"
  principal_id         = var.aks_principal_id
}