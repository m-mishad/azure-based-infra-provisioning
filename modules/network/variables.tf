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

variable "virtual_network_name" {
  description = "Name of the virtual network"
  type        = string
}

# variable "subnet" {
#   description = "Name of the subnet"
#   type        = string
# }

variable "azure_deploy_postgres" {
  description = "Create Azure Postgres values are true or false"
  type        = bool
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}
