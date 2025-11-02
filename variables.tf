variable "location" {
  description = "The region in which resources will be deployed."
}

variable "lifecycle_type" {
  description = "The type of environment, dev/prod"
  validation {
    condition     = contains(["dev", "prod"], var.lifecycle_type)
    error_message = "The lifecycle_type must be either 'dev' or 'prod'."
  }
}

variable "target_tenant_id" {
}

variable "target_subscription_id" {
}


##################

#Postgres related settings:

variable "azure_deploy_postgres" {
  description = "Create Azure Postgres values are true or false"
  type        = bool
  default     = true
}

variable "admin_username" {
  description = "Any resource (such as VMs or postgres instances) will use this to set the admin username"
}

variable "admin_password" {
  description = "Any resource (such as VMs or postgres instances) will use this to set the admin password"
}

variable "postgres_config" {
  description = "postgres configuration. This is a map of postgres cconfigurations."
  type = map(object({
    postgres_version = string
    storage_size     = number
    postgres_sku     = string
  }))
  default = {
    instance = {
      postgres_version = "16"
      storage_size     = 32768
      postgres_sku     = "GP_Standard_D4s_v3"
    }
  }
}

########## AKS related

variable "k8s_version" {
  type        = string
  description = "The version of Kubernetes to deploy. When upgrading to a new minor version, lifecycle ignore hook for k8s version in aks module needs to be commented out"
  default     = "1.32"
  validation {
    condition     = can(regex("^[0-9]+.[0-9]+$", var.k8s_version))
    error_message = "Should use minor version, instead of exact patch version."
  }
}

variable "aks_enable_policy" {
  description = "Deploy Azure Policy to AKS as an add-on"
  type        = bool
  default     = false
}

variable "aks_set_availability_zones" {
  description = "Set AKS availabilizy zone, values are [\"1\"], [\"1\",\"2\"] and [\"1\",\"2\",\"3\"]"
  default     = ["1"]
  type        = list(string)
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
  validation {
    condition     = length(var.aks_nodepool_configuration) >= 2
    error_message = "At least 2 nodepool definitions are required."
  }
  validation {
    condition     = contains(keys(var.aks_nodepool_configuration), "systempool")
    error_message = "A nodepool named 'systempool' is required."
  }
  default = {
    "systempool" = {
      "max_count"              = 3
      "min_count"              = 1
      "os_disk_size_gb"        = 50
      "os_disk_type"           = "Ephemeral"
      "vm_size"                = "Standard_D2s_v3"
      "enable_host_encryption" = true
      "orchestrator_version"   = "1.32"
      "os_sku"                 = "AzureLinux"
    },
    "nodepool1" = {
      "max_count"              = 10
      "min_count"              = 1
      "os_disk_size_gb"        = 50
      "os_disk_type"           = "Ephemeral"
      "vm_size"                = "Standard_D4s_v3"
      "enable_host_encryption" = true
      "orchestrator_version"   = "1.32"
      "os_sku"                 = "AzureLinux"
    },
  }
}

variable "aks_local_account_disabled" {
  description = "When disabled, only Entra ID based accounts can be used to access the AKS cluster."
  type        = bool
  default     = false
}

variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Indicates if AKS API is enabled Private or Public"
  default     = false
}




##################################
# AKS Azure Policy related variables
##################################
variable "allowed_registries" {
  description = "The allowed registry a container can only use images from"
  type        = list(string)
  default     = ["mcr.microsoft.com"]
}


# Audit log variables

variable "audit_events_log_analytics_workspace_id" {
  description = "The Log Analytics workspace ID for audit events. Leaving this empty will use main workspace."
  type        = string
  default     = ""
}

###############################
# Diagnostic settings variables
###############################

variable "enable_diagnostic_settings" {
  type        = bool
  default     = true
  description = "Toggle to enable/disable diagnostic settings configuration."
}

#######################
# Flow logs variables
#######################

variable "enable_flow_logs" {
  description = "Enable or disable network watcher flow logs"
  type        = bool
  default     = false
}

variable "nsg_ids" {
  description = "A map of NSG IDs to create flow logs for"
  type        = map(string)
  default     = {}
}