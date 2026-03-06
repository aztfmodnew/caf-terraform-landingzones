terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9"
    }
  }
  required_version = ">= 1.8.0"
}

data "azurerm_client_config" "current" {}
