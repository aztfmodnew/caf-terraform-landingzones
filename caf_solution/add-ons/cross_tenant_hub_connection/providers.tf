locals {
  landingzone = {
    current = {
      storage_account_name = var.tfstate_storage_account_name
      container_name       = var.tfstate_container_name
      resource_group_name  = var.tfstate_resource_group_name
    }
    lower = {
      storage_account_name = var.lower_storage_account_name
      container_name       = var.lower_container_name
      resource_group_name  = var.lower_resource_group_name
    }
  }
}

data "terraform_remote_state" "remote" {
  for_each = try(var.landingzone.tfstates, {})

  backend = var.landingzone.backend_type
  config = {
    container_name       = try(each.value.workspace, local.landingzone[try(each.value.level, "current")].container_name)
    key                  = each.value.tfstate
    resource_group_name  = try(each.value.resource_group_name, local.landingzone[try(each.value.level, "current")].resource_group_name)
    sas_token            = try(each.value.sas_token, null) != null ? var.sas_token : null
    storage_account_name = try(each.value.storage_account_name, local.landingzone[try(each.value.level, "current")].storage_account_name)
    subscription_id      = try(each.value.subscription_id, data.azurerm_client_config.current.subscription_id)
    tenant_id            = try(each.value.tenant_id, data.azurerm_client_config.current.tenant_id)
    use_azuread_auth     = try(each.value.use_azuread_auth, true)
  }
}

data "azurerm_client_config" "current" {
  provider = azurerm.vnet
}

provider "azurerm" {
  alias                           = "virtual_hub"
  resource_provider_registrations = "none"
  subscription_id = var.virtual_hub_subscription_id
  tenant_id       = var.virtual_hub_tenant_id

  # Source tenants for virtual networks.
  # Client ID must have permissions on those virtual_networks
  auxiliary_tenant_ids = try(var.landingzone.tfstates[var.virtual_hub_lz_key].auxiliary_tenant_ids, null)
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
  alias                           = "vnet"
  resource_provider_registrations = "none"
  subscription_id = var.virtual_network_subscription_id
  tenant_id       = var.virtual_network_tenant_id
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

