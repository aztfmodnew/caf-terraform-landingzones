
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.2"
    }
    alz = {
      source  = "azure/alz"
      version = "~> 0.16"
    }
  }
  required_version = ">= 1.9.0"
}

provider "azurerm" {
  partner_id = "ca4078f8-9bc4-471b-ab5b-3af6b86a42c8"
  # partner identifier for CAF Terraform landing zones.
  features {}
}

provider "azapi" {}

provider "alz" {
  library_references = concat(
    [
      {
        path = "platform/alz"
        ref  = var.alz_library_ref
      }
    ],
    var.library_path != null ? [{ custom_url = var.library_path }] : []
  )
}

data "azurerm_client_config" "current" {}
data "azapi_client_config" "current" {}
