variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group to fetch resources from"
  type        = string
}

variable "target_subscription_id" {
  description = "Target subscription ID"
}

variable "resource_group_id" {
  description = "The ID of the resource group where policies are to be applied"
  type        = string
}

variable "location" {
  description = "Azure Region where the Policy Assignment should exist"
  type        = string
}

variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}

variable "enable_diagnostic_settings" {
  type        = bool
  description = "enable/disable diagnostic settings configuration."
}