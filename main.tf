terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">=2.47.0"
    }
  }
}

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

data "azurerm_storage_account" "worklytics" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
}

# Create a storage container (https://<account>.blob.core.windows.net/<container>)
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
resource "azurerm_storage_container" "worklytics" {
  name                  = "${var.resource_name_prefix}container"
  storage_account_name  = var.storage_account_name
  container_access_type = "blob"
}

# Create Azure AD application: storage container access via federated identity
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
resource "azuread_application" "worklytics" {
  display_name = "${var.resource_name_prefix}app"

  feature_tags {
    hide       = true
    enterprise = false
    gallery    = false
  }

  owners = var.owners
}

# SP associated to the application (for authorization and role assignments)
resource "azuread_service_principal" "worklytics" {
  client_id = azuread_application.worklytics.client_id
}

# Create Azure AD federated identity
resource "azuread_application_federated_identity_credential" "worklytics" {
  application_id = azuread_application.worklytics.id
  display_name   = "${var.resource_name_prefix}federated-identity"
  description    = var.federated_identity_description
  audiences      = [var.federated_identity_audience]
  issuer         = var.federated_identity_issuer
  subject        = var.worklytics_tenant_id
}

# Assign roles to the application
resource "azurerm_role_assignment" "role_contributor" {
  scope                = data.azurerm_storage_account.worklytics.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.worklytics.id
}

# Role for the synchronization script: User Delegation Key via Azure SDK
resource "azurerm_role_assignment" "role_delegator" {
  scope                = data.azurerm_storage_account.worklytics.id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = azuread_service_principal.worklytics.id
}

resource "local_file" "todo" {
  filename = "TODO.md"
  content  = <<EOT
Configuration values for Worklytics:

Storage Account: ${var.storage_account_name}
Container Name: ${azurerm_storage_container.worklytics.name}
Client ID: ${azuread_application.worklytics.client_id}
Tenant ID: ${var.azure_tenant_id}

https://app.worklytics.co/analytics/data-export/connect?type=AZURE_BLOB_STORAGE&storageAccount=${var.storage_account_name}&container=${azurerm_storage_container.worklytics.name}&clientId=${azuread_application.worklytics.client_id}&tenantId=${var.azure_tenant_id}

EOT
}
