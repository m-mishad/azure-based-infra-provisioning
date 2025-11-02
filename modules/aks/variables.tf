variable "vnet_id" {
  description = ""
  type        = string
}

variable "managedid_principal_id" {
  description = ""
  type        = string
}

variable "managedid_object_id" {
  description = ""
  type        = string
}

variable "tags" {
  description = "The tags for the resource."
  type        = map(string)
}

variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}

variable "resource_group_name" {
  description = ""
  type        = string
}

variable "location" {
  description = ""
  type        = string
}

variable "k8s_version" {
  type        = string
  description = "The version of Kubernetes to use for the AKS cluster"
}

variable "admin_username" {
  description = ""
  type        = string
}

variable "admin_ssh_pub_key" {
  description = ""
  type        = string
}

variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Indicates if AKS API is enabled Private or Public"
}

variable "aks_api_subnet_id" {
  description = ""
  type        = string
}

variable "audit_events_log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace ID to send audit events to"
  type        = string
}

variable "aks_local_account_disabled" {
  description = "value"
  type        = bool
}

variable "aks_nodepool_configuration" {
  description = "AKS nodepool configuration. This is a map of nodepool names to nodepool configurations."
  type = map(object({
    max_count              = number
    min_count              = number
    vm_size                = string
    os_disk_size_gb        = number
    os_disk_type           = string
    enable_host_encryption = bool
    orchestrator_version   = string
    os_sku                 = string
  }))
}

variable "aks_set_availability_zones" {
  description = "The Availability Zone of the AKS cluster."
  type        = list(string)
  default     = ["1"]

  validation {
    condition = can(
      contains(["1"], var.aks_set_availability_zones) ||
      contains(["1", "2"], var.aks_set_availability_zones) ||
      contains(["2", "3"], var.aks_set_availability_zones) ||
      contains(["1", "3"], var.aks_set_availability_zones) ||
      contains(["1", "2", "3"], var.aks_set_availability_zones)
    )
    error_message = "Possible values for aks_set_availability_zones are [\"1\"], [\"1\",\"2\"] and [\"1\",\"2\",\"3\"]."
  }
}

variable "aks_system_subnet_id" {
  description = ""
  type        = string
}

variable "aks_pods_subnet_id" {
  description = ""
  type        = string
}

variable "aks_user_subnet_id" {
  description = ""
  type        = string
}

variable "aks_enable_policy" {
  description = "Deploy Azure Policy to AKS as an add-on"
}

variable "keyvault_id" {
  description = ""
  type        = string
}


variable "enable_diagnostic_settings" {
  type        = bool
  description = "enable/disable diagnostic settings configuration."
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID"
  type        = string
}

variable "allowed_registries" {
  description = "The allowed registry a container can only use images from"
  type        = list(string)
  default     = ["mcr.microsoft.com"]
}

