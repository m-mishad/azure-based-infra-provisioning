variable "short_resource_name_prefix" {
  description = "The prefix for the short resource name."
}

variable "tags" {
  description = "The tags for the resource."
  type        = map(string)
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The location of the resource."
  type        = string
}

variable "delegated_subnet_id" {
  description = "The ID of the delegated subnet."
  type        = string
}

variable "vnet_id" {
  description = "The ID of the virtual network."
  type        = string
}

variable "admin_login" {
  description = "The admin login for the PostgreSQL server."
  type        = string
}

variable "admin_password" {
  description = "The admin password for the PostgreSQL server."
  type        = string
}

variable "pg_version" {
  description = "The version of the PostgreSQL server."
  type        = string
}

variable "sku_name" {
  description = "The SKU name for the PostgreSQL server."
  type        = string
}

variable "storage_mb" {
  description = "The storage size in MB for the PostgreSQL server."
  type        = number
}

# variable "env_type" {
#   description = "The environment type (Dev/Prod)."
#   type        = string
# }

variable "priv_dns_zone_id" {
  description = "The ID of the private DNS zone."
  type        = string
}

variable "enable_prevent_delete_lock" {
  description = "Determines whether management locks are applied to the Postgres Flexible server resource"
  type        = bool
}

variable "instance_key" {
  description = "A unique key to differentiate instances"
  type        = string
}

variable "resource_prefix" {
  description = "Resource name prefix from root/locals.tf"
  type        = string
}