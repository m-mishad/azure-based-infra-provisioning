variable "short_resource_name_prefix" {
  description = ""
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

variable "target_tenant_id" {
  description = ""
  type        = string
}

variable "kv_name" {
  description = ""
  type        = string
}

variable "vnet_id" {
  description = ""
  type        = string
}

variable "pods_id" {
  description = ""
  type        = string
}

variable "whitelist_ip" {
  description = ""
  type        = string
}

variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the KV resource"
  type        = bool
}

variable "managedid_object_id" {
  description = ""
  type        = string
}

variable "runner_object_id" {
  description = ""
  type        = string
}

variable "storage_account_primary_connection_string" {
  description = "Storage account PCS"
  type        = string
}

variable "privatelinks_subnet_id" {
  description = ""
  type        = string
}

variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}