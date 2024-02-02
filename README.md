# Worklytics Export to Azure Terraform Module

This module creates infra to support exporting data from Worklytics to [Azure Blob Storage].

## Usage

via GitHub:
```hcl
module "worklytics-export" {
  source  = "git::https://github.com/worklytics/terraform-azure-worklytics-export/"

  # numeric ID of your Worklytics Tenant SA
  worklytics_tenant_id = "123123123123"
  # numeric ID of your Azure Tenant
  azure_tenant_id      = "123123123123"
  # the name of the Azure Storage Account were the container to store the data will be created
  storage_account_name = "worklytics"
  # the name of the resource group where the storage account is located
  resource_group_name  = "worklytics"
}
```

## Outputs

#### `worklytics_export_container`
The Terraform resource created as the export container. See [`azurerm_storage_container`] for details.
This is useful to compose with the other `azurerm_*` resources to apply further configurations.

## Compatibility

This module is meant for use with Terraform 1.0+. If you find incompatibilities using Terraform >=
1.0, please open an issue.

## Usage Tips

### Existing Container

If you wish to export Worklytics data to an existing container, use a Terraform import as follows:

```bash
terraform import azurerm_storage_container.worklytics <https://example.blob.core.windows.net/container>
```

## Development

This module is written and maintained by [Worklytics, Co.](https://worklytics.co/) and intended to
guide our customers in setting up their own infra to export data from Worklytics to Azure Blob Storage.

(c) 2024 Worklytics, Co

[Azure Blob Storage]: https://learn.microsoft.com/en-us/azure/storage/blobs/
[`azurerm_storage_container`]: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
