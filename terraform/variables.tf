# =============================================================================
# Input Variables
# =============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "demo"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "acr_sku" {
  description = "SKU for Azure Container Registry"
  type        = string
  default     = "Standard"
}

variable "aks_node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 3
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}
