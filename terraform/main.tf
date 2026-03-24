# =============================================================================
# Contoso Pet Store - Infrastructure as Code
# Terraform root module
# =============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }

  # Remote state in Azure Storage (created manually once)
  # See terraform/README.md for bootstrap instructions
  backend "azurerm" {
    resource_group_name  = "rg-petstore-tfstate"
    storage_account_name = "stpetstoretfstate"
    container_name       = "tfstate"
    key                  = "petstore.terraform.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

provider "azuread" {}

# =============================================================================
# Data Sources
# =============================================================================

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

# =============================================================================
# Resource Group
# =============================================================================

resource "azurerm_resource_group" "main" {
  name     = "rg-petstore-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# =============================================================================
# Modules
# =============================================================================

module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  vnet_address_space  = var.vnet_address_space
  tags                = local.common_tags
}

module "acr" {
  source = "./modules/acr"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  sku                 = var.acr_sku
  tags                = local.common_tags
}

module "keyvault" {
  source = "./modules/keyvault"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tenant_id           = data.azurerm_client_config.current.tenant_id
  admin_object_id     = data.azurerm_client_config.current.object_id
  tags                = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  tags                = local.common_tags
}

module "aks" {
  source = "./modules/aks"

  resource_group_name     = azurerm_resource_group.main.name
  location                = azurerm_resource_group.main.location
  environment             = var.environment
  node_count              = var.aks_node_count
  node_vm_size            = var.aks_node_vm_size
  vnet_subnet_id          = module.networking.aks_subnet_id
  acr_id                  = module.acr.acr_id
  log_analytics_id        = module.monitoring.log_analytics_workspace_id
  tags                    = local.common_tags
}

# =============================================================================
# Store secrets in Key Vault
# =============================================================================

resource "azurerm_key_vault_secret" "appinsights_connection_string" {
  name         = "appinsights-connection-string"
  value        = module.monitoring.appinsights_connection_string
  key_vault_id = module.keyvault.key_vault_id
}
