terraform {
  required_providers {
    // azurerm version driven by the caf module
    // azuread version driven by the caf module
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    azurecaf = {
      source  = "aztfmodnew/azurecaf"
      version = "~> 1.2.28"
    }
  }
  required_version = ">= 1.8.0"
}


provider "azurerm" {
  # partner identifier for CAF Terraform landing zones.
  partner_id = "ca4078f8-9bc4-471b-ab5b-3af6b86a42c8"
  features {
    api_management {
      purge_soft_delete_on_destroy = try(var.provider_azurerm_features_api_management.purge_soft_delete_on_destroy, null)
      recover_soft_deleted         = try(var.provider_azurerm_features_api_management.recover_soft_deleted, null)
    }
    app_configuration {
      purge_soft_delete_on_destroy = try(var.provider_azurerm_features_app_configuration.purge_soft_delete_on_destroy, null)
      recover_soft_deleted         = try(var.provider_azurerm_features_app_configuration.recover_soft_deleted, null)
    }
    application_insights {
      disable_generated_rule = try(var.provider_azurerm_features_application_insights.disable_generated_rule, null)
    }
    cognitive_account {
      purge_soft_delete_on_destroy = var.provider_azurerm_features_cognitive_account.purge_soft_delete_on_destroy
    }
    key_vault {
      purge_soft_delete_on_destroy                            = try(var.provider_azurerm_features_keyvault.purge_soft_delete_on_destroy, false)
      purge_soft_deleted_certificates_on_destroy              = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_certificates_on_destroy, null)
      purge_soft_deleted_keys_on_destroy                      = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_keys_on_destroy, null)
      purge_soft_deleted_secrets_on_destroy                   = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_secrets_on_destroy, null)
      purge_soft_deleted_hardware_security_modules_on_destroy = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_hardware_security_modules_on_destroy, null)
      recover_soft_deleted_certificates                       = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_certificates, null)
      recover_soft_deleted_key_vaults                         = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_key_vaults, true)
      recover_soft_deleted_keys                               = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_keys, null)
      recover_soft_deleted_secrets                            = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_secrets, null)
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = try(var.provider_azurerm_features_log_analytics_workspace.permanently_delete_on_destroy, null)
    }
    managed_disk {
      expand_without_downtime = try(var.provider_azurerm_features_managed_disk.expand_without_downtime, null)
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.provider_azurerm_features_resource_group.prevent_deletion_if_contains_resources
    }
    template_deployment {
      delete_nested_items_during_deletion = var.provider_azurerm_features_template_deployment.delete_nested_items_during_deletion
    }
    virtual_machine {
      delete_os_disk_on_deletion     = try(var.provider_azurerm_features_virtual_machine.delete_os_disk_on_deletion, null)
      graceful_shutdown              = try(var.provider_azurerm_features_virtual_machine.graceful_shutdown, true)
      skip_shutdown_and_force_delete = try(var.provider_azurerm_features_virtual_machine.skip_shutdown_and_force_delete, null)
    }
    virtual_machine_scale_set {
      force_delete                  = try(var.provider_azurerm_features_virtual_machine_scale_set.force_delete, false)
      roll_instances_when_required  = try(var.provider_azurerm_features_virtual_machine_scale_set.roll_instances_when_required, null)
      scale_to_zero_before_deletion = try(var.provider_azurerm_features_virtual_machine_scale_set.scale_to_zero_before_deletion, null)
    }
  }
}

provider "azurerm" {
  alias                           = "vhub"
  resource_provider_registrations = "none"
  features {}
  subscription_id = local.connectivity_subscription_id
  tenant_id       = local.connectivity_tenant_id
}

provider "azuread" {
  partner_id = "ca4078f8-9bc4-471b-ab5b-3af6b86a42c8"
}


resource "random_string" "prefix" {
  count   = var.prefix == null ? 1 : 0
  length  = 4
  special = false
  upper   = false
  numeric = false
}

locals {
  landingzone_tag = {
    "landingzone" = var.landingzone.key
  }

  tags = merge(local.global_settings.tags, local.landingzone_tag, { "caf_environment" = local.global_settings.environment }, { "rover_version" = var.rover_version }, var.tags)

  global_settings = {
    default_region     = var.default_region
    environment        = var.environment
    inherit_tags       = var.inherit_tags
    passthrough        = var.passthrough
    prefix             = var.prefix
    prefixes           = var.prefix == "" ? null : [try(random_string.prefix.0.result, var.prefix)]
    prefix_with_hyphen = var.prefix == "" ? null : format("%s", try(random_string.prefix.0.result, var.prefix))
    random_length      = var.random_length
    regions            = var.regions
    slug_version       = var.slug_version
    tags               = var.tags
    use_slug           = var.use_slug
  }

  tfstates = tomap(
    {
      (var.landingzone.key) = local.backend[var.landingzone.backend_type]
    }
  )

  backend = {
    azurerm = {
      storage_account_name = module.launchpad.storage_accounts[var.launchpad_key_names.tfstates[0]].name
      container_name       = module.launchpad.storage_accounts[var.launchpad_key_names.tfstates[0]].containers["tfstate"].name
      resource_group_name  = module.launchpad.storage_accounts[var.launchpad_key_names.tfstates[0]].resource_group_name
      key                  = var.tf_name
      level                = var.landingzone.level
      tenant_id            = data.azurerm_client_config.current.tenant_id
      subscription_id      = data.azurerm_client_config.current.subscription_id
    }
    remote = {
      hostname     = try(var.tfstate_hostname, "app.terraform.io")
      organization = var.tfstate_organization
      workspaces = {
        name = var.workspace
      }
    }
  }

}

data "azurerm_client_config" "current" {}