
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

variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}

variable "appgw_set_availability_zones" {
  description = ""
  type        = list(string)
  default     = ["1"]

  validation {
    condition = can(
      contains(["1"], var.appgw_set_availability_zones) ||
      contains(["1", "2"], var.appgw_set_availability_zones) ||
      contains(["1", "2", "3"], var.appgw_set_availability_zones)
    )

    error_message = "Possible values for appgw_set_availability_zones are [\"1\"], [\"1\",\"2\"] and [\"1\",\"2\",\"3\"]."
  }
}

variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the AppGtw public-ip resource"
  type        = bool
}

variable "appgw_subnet_id" {
  description = ""
  type        = string
}

variable "managedid_object_id" {
  description = ""
  type        = string
}

variable "aks_principal_id" {
  description = "Regional managed identity used by the AKS cluster"
  type        = string
}
