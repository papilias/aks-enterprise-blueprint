variable "project_name" {
  description = "Prefix used for naming Azure resources"
  type        = string
  default     = "aks-enterprise"
}

variable "environment" {
  description = "Deployment environment (staging or prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for deployment"
  type        = string
  default     = "uksouth"
}

variable "kubernetes_version" {
  description = "Kubernetes control plane and node pool version"
  type        = string
  default     = "1.30"
}

variable "system_node_vm_size" {
  description = "VM SKU for the dedicated system node pool"
  type        = string
  default     = "Standard_D2ds_v5"
}

variable "user_node_vm_size" {
  description = "VM SKU for the FIPS-enabled workload node pool"
  type        = string
  default     = "Standard_D4ds_v5"
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra ID group Object IDs granted AKS Cluster Admin RBAC"
  type        = list(string)
  default     = []
}
