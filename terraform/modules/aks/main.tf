# =============================================================================
# Azure Kubernetes Service Module
# =============================================================================

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "node_count" { type = number }
variable "node_vm_size" { type = string }
variable "vnet_subnet_id" { type = string }
variable "acr_id" { type = string }
variable "log_analytics_id" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-petstore-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = "petstore-${var.environment}"

  default_node_pool {
    name                = "system"
    node_count          = var.node_count
    vm_size             = var.node_vm_size
    vnet_subnet_id      = var.vnet_subnet_id
    os_disk_size_gb     = 30
    max_pods            = 50

    upgrade_settings {
      max_surge = "1"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
    load_balancer_sku = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_id
  }

  tags = var.tags
}

# ── ACR Pull permission via Managed Identity ─────────────────────────────────

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "cluster_name" {
  value = azurerm_kubernetes_cluster.main.name
}

output "cluster_fqdn" {
  value = azurerm_kubernetes_cluster.main.fqdn
}

output "kube_config_raw" {
  value     = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive = true
}

output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}
