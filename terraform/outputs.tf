# =============================================================================
# Outputs - consumed by CI/CD pipeline and K8s manifests
# =============================================================================

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = module.acr.acr_login_server
}

output "acr_name" {
  description = "ACR name"
  value       = module.acr.acr_name
}

output "aks_cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.cluster_name
}

output "aks_cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = module.aks.cluster_fqdn
}

output "appinsights_connection_string" {
  description = "Application Insights connection string"
  value       = module.monitoring.appinsights_connection_string
  sensitive   = true
}

output "appinsights_app_id" {
  description = "Application Insights App ID (for API queries)"
  value       = module.monitoring.appinsights_app_id
}

output "appinsights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = module.monitoring.appinsights_instrumentation_key
  sensitive   = true
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = module.keyvault.key_vault_name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = module.keyvault.key_vault_uri
}

output "vnet_id" {
  description = "VNet ID"
  value       = module.networking.vnet_id
}
