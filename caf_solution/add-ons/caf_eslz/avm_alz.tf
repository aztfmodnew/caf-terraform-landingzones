# Wrapper module that calls Azure/avm-ptn-alz/azurerm while maintaining the same
# variable interface as the deprecated Azure/caf-enterprise-scale/azurerm module.
# Translation locals are in archetype_config_overrides.tf and custom_landing_zones.tf.

module "alz" {
  source  = "Azure/avm-ptn-alz/azurerm"
  version = "~> 0.19"

  architecture_name  = var.architecture_name
  location           = local.global_settings.regions[local.global_settings.default_region]
  parent_resource_id = var.root_parent_id == null ? data.azapi_client_config.current.tenant_id : var.root_parent_id

  policy_assignments_to_modify = local.policy_assignments_to_modify_map
  subscription_placement       = local.subscription_placement_map

  enable_telemetry = !var.disable_telemetry
}

locals {
  # Kept for backward compatibility with subscription ID resolution logic
  subscription_id_connectivity = var.subscription_id_connectivity == null ? data.azurerm_client_config.current.subscription_id : var.subscription_id_connectivity
  subscription_id_management   = var.subscription_id_management == null ? data.azurerm_client_config.current.subscription_id : var.subscription_id_management
  subscription_id_identity     = var.subscription_id_identity == null ? data.azurerm_client_config.current.subscription_id : var.subscription_id_identity
}