terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "azurerm_resource_group" "aks" {
  name     = "rg-${local.name_prefix}"
  location = var.location
}

resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${local.name_prefix}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.240.0.0/16"]
}

resource "azurerm_subnet" "nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.240.1.0/24"]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${local.name_prefix}"
  location                  = azurerm_resource_group.aks.location
  resource_group_name       = azurerm_resource_group.aks.name
  dns_prefix                = local.name_prefix
  kubernetes_version        = var.kubernetes_version
  local_account_disabled    = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  default_node_pool {
    name                        = "system"
    vm_size                     = var.system_node_vm_size
    os_sku                      = "AzureLinux"
    vnet_subnet_id              = azurerm_subnet.nodes.id
    auto_scaling_enabled        = true
    min_count                   = 2
    max_count                   = 3
    only_critical_addons_enabled = true
  }

  identity {
    type = "SystemAssigned"
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    service_cidr      = "10.241.0.0/16"
    dns_service_ip    = "10.241.0.10"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "workloads" {
  name                  = "workloads"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.user_node_vm_size
  os_sku                = "AzureLinux"
  fips_enabled          = true
  vnet_subnet_id        = azurerm_subnet.nodes.id
  auto_scaling_enabled  = true
  min_count             = 2
  max_count             = 6
  mode                  = "User"

  node_labels = {
    "workload-tier" = "enterprise"
    "compliance"    = "fips-140"
  }
}
