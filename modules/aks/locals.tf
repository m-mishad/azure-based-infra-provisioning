locals {
  aks_nodepools = {
    for k, v in var.aks_nodepool_configuration : k => v if k != "systempool"
  }
}