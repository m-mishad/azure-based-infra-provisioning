
resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${var.resource_prefix}-psql-${var.instance_key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  version             = var.pg_version

  delegated_subnet_id           = var.delegated_subnet_id
  public_network_access_enabled = false

  private_dns_zone_id    = var.priv_dns_zone_id
  administrator_login    = var.admin_login
  administrator_password = var.admin_password
  zone                   = "1"

  storage_mb = var.storage_mb
  tags       = var.tags

  sku_name = var.sku_name

}

resource "azurerm_management_lock" "postgres_lock" {
  count      = var.enable_prevent_delete_lock ? 1 : 0
  lock_level = "CanNotDelete"
  name       = "postgres-delete-lock-${var.instance_key}"
  scope      = azurerm_postgresql_flexible_server.main.id
}

resource "azurerm_postgresql_flexible_server_configuration" "main" {
  name      = "azure.extensions"
  server_id = azurerm_postgresql_flexible_server.main.id
  value     = "PG_STAT_STATEMENTS,PG_TRGM,PGCRYPTO,POSTGIS,UNACCENT,FUZZYSTRMATCH"
}
