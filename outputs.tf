output "worklytics_export_container" {
  value       = azurerm_storage_container.worklytics.name
  description = "The Terraform resource created as the export container. See https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container for details."
}

output "worklytics_export_app_client_id" {
  value       = azuread_application.worklytics.client_id
  description = "The Entra App for federated access to the container"
}

output "todo_markdown" {
  value       = var.todos_as_outputs ? local.todo_content : null
  description = "Actions that must be performed outside of Terraform (markdown format)."
}
