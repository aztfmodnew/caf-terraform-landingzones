module "dynamic_keyvault_secrets" {
  source  = "aztfmodnew/caf/azurerm//modules/security/dynamic_keyvault_secrets"
  version = "4.44.0"

  for_each = {
    for keyvault_key, secrets in try(var.dynamic_keyvault_secrets, {}) : keyvault_key => {
      for key, value in secrets : key => value
      if try(value.value, null) == null
    }
  }

  settings = each.value
  keyvault = module.solution.keyvaults[each.key]
  objects  = module.solution
}