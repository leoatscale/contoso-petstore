# =============================================================================
# Monitoring Module - Log Analytics + Application Insights
# =============================================================================

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "environment" { type = string }
variable "tags" { type = map(string) }

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-petstore-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_application_insights" "main" {
  name                = "appi-petstore-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = var.tags
}

# ── Alert: High Error Rate (>5%) ─────────────────────────────────────────────

resource "azurerm_monitor_smart_detector_alert_rule" "failure_anomalies" {
  name                = "alert-failure-anomalies-${var.environment}"
  resource_group_name = var.resource_group_name
  detector_type       = "FailureAnomaliesDetector"
  scope_resource_ids  = [azurerm_application_insights.main.id]
  severity            = "Sev1"
  frequency           = "PT1M"

  action_group {
    ids = []  # Add action group IDs for email/Teams notifications
  }

  tags = var.tags
}

# ── Outputs ──────────────────────────────────────────────────────────────────

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.main.id
}

output "appinsights_connection_string" {
  value     = azurerm_application_insights.main.connection_string
  sensitive = true
}

output "appinsights_instrumentation_key" {
  value     = azurerm_application_insights.main.instrumentation_key
  sensitive = true
}

output "appinsights_app_id" {
  value = azurerm_application_insights.main.app_id
}
