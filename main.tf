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

locals {
  # This is the recommended value from MSFT, as it is what AAD expects to be in the "aud" claim of
  # the token. See docs:
  # https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#important-considerations-and-restrictions
  federated_identity_audience = "api://AzureADTokenExchange"
  todo_content                = <<EOT

# Configure Data Export in Worklytics

1. Ensure you're authenticated with Worklytics. Either sign-in at [https://${var.worklytics_host}](https://${var.worklytics_host})
  with your organization's SSO provider *or* request OTP link from your Worklytics support.
2. Visit `https://${var.worklytics_host}/analytics/data-export/connect?type=AZURE_BLOB_STORAGE&container=${azurerm_storage_container.worklytics.name}&clientId=${azuread_application.worklytics.client_id}&tenantId=${var.azure_tenant_id}`
3. Review any additional settings (such as the Dataset type you'd like to export) and adjust
  values as you see fit, then click "Create Data Export".

Alternatively, you may follow the manual instructions below:

1. Visit [https://${var.worklytics_host}/analytics/data-export](https://${var.worklytics_host}/analytics/data-export)
  (or login into Worklytics, and navigate to Manage --> Export Data).
2. Click on the 'Create New Data Export' button in the upper right.
3. Fill in the form with the following values:
  - **Data Export Name** - choose a name that will help you identify this export in the future.
  - **Data Export Type** - choose the type of data you'd like to export. Check our
    [Data Export Documentation](https://${var.worklytics_host}/docs/data-export) for a complete
    description of all the available datasets.
  - **Data Destination** - choose 'Azure Blob Storage', and use the following values for each field:
    - Container Name: ${azurerm_storage_container.worklytics.name}
    - Storage Account: ${var.storage_account_name}
    - Client ID: ${azuread_application.worklytics.client_id}
    - Tenant ID: ${var.azure_tenant_id}
EOT
}

# Create a storage container (https://<account>.blob.core.windows.net/<container>)
# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
resource "azurerm_storage_container" "worklytics" {
  name                  = "${var.resource_name_prefix}export-container"
  storage_account_name  = var.storage_account_name
  container_access_type = "private"
}

# Create Azure AD application: storage container access via federated identity
# https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application
resource "azuread_application" "worklytics" {
  display_name = "${var.resource_name_prefix}export-connector"

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
  display_name   = "${var.resource_name_prefix}export-federated-identity"
  description    = var.federated_identity_description
  audiences      = [local.federated_identity_audience]
  issuer         = var.federated_identity_issuer
  subject        = var.worklytics_tenant_id
}

# Assign roles to the application for writing and reading contents of the storage container
resource "azurerm_role_assignment" "role_contributor" {
  scope                = azurerm_storage_container.worklytics.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.worklytics.id
}

# Role for the synchronization script: User Delegation Key via Azure SDK
resource "azurerm_role_assignment" "role_delegator" {
  scope                = azurerm_storage_container.worklytics.resource_manager_id
  role_definition_name = "Storage Blob Delegator"
  principal_id         = azuread_service_principal.worklytics.id
}

resource "local_file" "todo" {
  count = var.todos_as_local_files ? 1 : 0

  filename = "TODO - configure export in worklytics.md"

  content = local.todo_content
}
