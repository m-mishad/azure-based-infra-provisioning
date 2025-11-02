variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}

variable "tags" {
  description = ""
  type        = map(string)
}

variable "resource_group_name" {
  description = ""
  type        = string
}

variable "location" {
  description = ""
  type        = string
}


variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the Storage Account resource"
  type        = bool
}

variable "enable_flow_logs" {
  description = "Enable or disable network watcher flow logs"
  type        = bool
}

variable "nsg_ids" {
  description = "A map of NSG IDs to create flow logs for"
  type        = map(string)
}

variable "storage_account_id" {
  description = "Storage Account ID"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "enable_diagnostic_settings" {
  type        = bool
  description = "enable/disable diagnostic settings configuration."
}