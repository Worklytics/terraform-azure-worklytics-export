terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

module "worklytics_export" {
  source = "../.."

  resource_name_prefix = var.resource_name_prefix
  worklytics_tenant_id = var.worklytics_tenant_id
  azure_tenant_id      = var.azure_tenant_id
  resource_group_name  = var.resource_group_name
  storage_account_name = var.storage_account_name
}
