variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}

variable "resource_group" {
  description = "Azure Resource Group (azurerm_resource_group)"
  type = object({
    name     = string
    location = string
  })
}

variable "tags" {
  description = "A set of tags that are added to all resourcess"
  type        = map(string)
}

variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the Audit Log Storage Account resource"
  type        = bool
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "enable_diagnostic_settings" {
  type        = bool
  description = "enable/disable diagnostic settings configuration."
}