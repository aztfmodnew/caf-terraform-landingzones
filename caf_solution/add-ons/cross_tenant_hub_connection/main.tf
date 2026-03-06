
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
  required_version = ">= 1.8.0"
}


# provider "azurerm" {
#   features {}
#   skip_provider_registration = true
# }

# data "azurerm_client_config" "current" {}

