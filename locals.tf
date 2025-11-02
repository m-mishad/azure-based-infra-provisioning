locals {
  description = "Local variables."

  lifecycle_types = {
    "prod" = "p"
    "dev" = "d"
  }
  short_lifecycle_type       = local.lifecycle_types[lower(var.lifecycle_type)]
  short_region               = local.region_short_names[var.location]
  region                     = local.region_names[var.location]
  short_resource_name_prefix = "${upper(substr(var.lifecycle_type, 0, 1))}${upper(local.short_region)}"
  resource_prefix            = "${local.short_lifecycle_type}-${local.short_region}"


  rg_name     = "${local.resource_prefix}-rg"
  kv_name     = "${local.resource_prefix}-kv"
  vnet_name   = "${local.resource_prefix}-vnet"
  subnet_name = "${local.resource_prefix}-snet"


  tags = {
    location       = var.location
    environment    = var.lifecycle_type
    resource_group = local.rg_name
  }

  region_names = {
    "Central US" = "CENTRALUS"
    "East US"    = "EASTUS"
  }

  region_short_names = {
    "Central US" = "cus"
    "East US"    = "eus"
  }
  enable_prevent_delete_lock = var.lifecycle_type == "prod" ? true : false
  audit_events_log_analytics_workspace_id = var.audit_events_log_analytics_workspace_id == "" ? azurerm_log_analytics_workspace.main[0].id : var.audit_events_log_analytics_workspace_id
}
