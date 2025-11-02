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

###################################


variable "regional_pods_id" {
  description = ""
  type        = string
}

variable "principal_id" {
  description = ""
  type        = string
}
variable "aks_principal_id" {
  description = ""
  type        = string
}
variable "vnet_id" {
  description = ""
  type        = string
}
variable "privatelinks_subnet_id" {
  description = ""
  type        = string
}

variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the Storage Account resource"
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