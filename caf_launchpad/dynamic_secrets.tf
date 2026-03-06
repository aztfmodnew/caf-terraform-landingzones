
module "dynamic_keyvault_secrets" {
  # source  = "aztfmodnew/caf/azurerm//modules/security/dynamic_keyvault_secrets"
  # version = "4.45.0"
  source = "/tf/caf-module//modules/security/dynamic_keyvault_secrets"

  for_each = try(var.dynamic_keyvault_secrets, {})

  settings = each.value
  keyvault = module.launchpad.keyvaults[each.key]
  objects  = module.launchpad
}
