# =============================================================================
# Azure Container Registry Module
# =============================================================================

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "sku" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_container_registry" "main" {
  name                = "acrpetstore${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false

  tags = var.tags
}

output "acr_id" {
  value = azurerm_container_registry.main.id
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "acr_name" {
  value = azurerm_container_registry.main.name
}
