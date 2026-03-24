locals {
  common_tags = {
    project     = "contoso-petstore"
    environment = var.environment
    managed_by  = "terraform"
    repository  = "contoso-petstore"
  }
}
