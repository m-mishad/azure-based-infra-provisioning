resource "azurerm_virtual_network" "main" {
  name                = var.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]
  tags                = var.tags
}

resource "azurerm_subnet" "postgres_subnet" {
  name                 = "${var.subnet_name}_postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.6.0/24"]
  depends_on           = [azurerm_virtual_network.main]
  service_endpoints = [
    "Microsoft.Sql",
    "Microsoft.Storage"
  ]

  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "postgres" {
  name                = "${azurerm_subnet.postgres_subnet.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "postgres" {
  subnet_id                 = azurerm_subnet.postgres_subnet.id
  network_security_group_id = azurerm_network_security_group.postgres.id
}

# Create a azure private dns zone for postgres
resource "azurerm_private_dns_zone" "main" {
  count               = var.azure_deploy_postgres ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  count                 = var.azure_deploy_postgres ? 1 : 0
  name                  = "postgres-network-link"
  private_dns_zone_name = azurerm_private_dns_zone.main[count.index].name
  virtual_network_id    = azurerm_virtual_network.main.id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

## AKS API Subnet
resource "azurerm_subnet" "aks_api" {
  name                 = "${var.subnet_name}-aks-api"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.1.0/27"]
  depends_on           = [azurerm_virtual_network.main]
  lifecycle {
    ignore_changes = all
  }
  delegation {
    name = "fs"

    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"

      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "aks_api" {
  name                = "${azurerm_subnet.aks_api.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_subnet_network_security_group_association" "aks_api" {
  subnet_id                 = azurerm_subnet.aks_api.id
  network_security_group_id = azurerm_network_security_group.aks_api.id
}



## AKS Pods subnet
resource "azurerm_subnet" "aks_pods" {
  name                 = "${var.subnet_name}-aks-pods"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.128.0.0/16"]
  depends_on           = [azurerm_virtual_network.main]
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage",
    "Microsoft.ContainerRegistry"
  ]
  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_network_security_group" "aks_pods" {
  name                = "${azurerm_subnet.aks_pods.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_subnet_network_security_group_association" "aks_pods" {
  subnet_id                 = azurerm_subnet.aks_pods.id
  network_security_group_id = azurerm_network_security_group.aks_pods.id
}

## AKS System Pool
resource "azurerm_subnet" "aks_systempool" {
  name                 = "${var.subnet_name}-aks-systempool"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.129.0.0/16"]
  depends_on           = [azurerm_virtual_network.main]
}

resource "azurerm_network_security_group" "aks_systempool" {
  name                = "${azurerm_subnet.aks_systempool.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks_systempool" {
  subnet_id                 = azurerm_subnet.aks_systempool.id
  network_security_group_id = azurerm_network_security_group.aks_systempool.id
}

## AKS User Pool
resource "azurerm_subnet" "aks_userpool" {
  name                 = "${var.subnet_name}-aks-userpool"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.130.0.0/16"]
  depends_on           = [azurerm_virtual_network.main]
}

resource "azurerm_network_security_group" "aks_userpool" {
  name                = "${azurerm_subnet.aks_userpool.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


resource "azurerm_subnet_network_security_group_association" "aks_userpool" {
  subnet_id                 = azurerm_subnet.aks_userpool.id
  network_security_group_id = azurerm_network_security_group.aks_userpool.id
}

## Private Link Subnet
resource "azurerm_subnet" "private_link" {
  name                 = "${var.subnet_name}-pl"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.2.0/24"]
  depends_on           = [azurerm_virtual_network.main]
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage"
  ]
}

resource "azurerm_network_security_group" "private_link" {
  name                = "${azurerm_subnet.private_link.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "private_link" {
  subnet_id                 = azurerm_subnet.private_link.id
  network_security_group_id = azurerm_network_security_group.private_link.id
}


## Azure Application Gateway Subnet
resource "azurerm_subnet" "application_gateway" {
  name                 = "${var.subnet_name}-agw"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = ["10.0.3.128/27"]
  service_endpoints = [
    "Microsoft.KeyVault",
    "Microsoft.Storage"
  ]

  depends_on = [azurerm_virtual_network.main]
}

resource "azurerm_network_security_group" "application_gateway" {
  name                = "${azurerm_subnet.application_gateway.name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


