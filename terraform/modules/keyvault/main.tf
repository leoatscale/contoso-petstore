# =============================================================================
# Azure Key Vault Module
# =============================================================================

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "tenant_id" { type = string }
variable "admin_object_id" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_key_vault" "main" {
  name                       = "kv-petstore-${var.environment}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false  # false for demo (easy cleanup)

  access_policy {
    tenant_id = var.tenant_id
    object_id = var.admin_object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge"
    ]

    key_permissions = [
      "Get", "List", "Create", "Delete"
    ]
  }

  tags = var.tags
}

output "key_vault_id" {
  value = azurerm_key_vault.main.id
}

output "key_vault_name" {
  value = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}
