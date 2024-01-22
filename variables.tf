variable "resource_name_prefix" {
  type        = string
  description = "Prefix to give to names of infra created by this module, where applicable."
  default     = "worklytics-export-"
}

variable "worklytics_tenant_id" {
  type        = string
  description = "Numeric ID of your Worklytics tenant's service account (obtain from Worklytics App)."

  validation {
    condition     = var.worklytics_tenant_id == null || can(regex("^\\d{21}$", var.worklytics_tenant_id))
    error_message = "`worklytics_tenant_id` must be a 21-digit numeric value. (or `null`, for pre-production use case where you don't want external entity to be allowed to assume the role)."
  }
}

variable "azure_tenant_id" {
  type = string
  # Used for deep linking to Worklytics data export configuration page
  description = "The Azure tenant ID where the application will be created"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account where the container will be created"
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the storage account is located"
}

variable "owners" {
  type        = set(string)
  description = "List of object ids to be set as owner of the application"
  default     = []
}

variable "federated_identity_description" {
  type        = string
  description = "Optionally, a description of the credential"
  default     = ""
}

variable "federated_identity_audience" {
  type = string
  # This is the recommended value from MSFT, as it is what AAD expects to be in the "aud" claim of
  # the token
  # See https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation-create-trust?pivots=identity-wif-apps-methods-azp#important-considerations-and-restrictions
  default = "api://AzureADTokenExchange"
}

variable "federated_identity_issuer" {
  type        = string
  description = "The URL of the external identity provider, which must match the issuer claim of the external token being exchanged. The combination of the values of issuer and subject must be unique on the app."
  default     = "https://accounts.google.com"
}
