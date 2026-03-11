output "objects" {
  description = "ALZ module outputs: management group IDs, policy assignment/definition/role resource IDs."
  value = merge(
    tomap(
      {
        (var.landingzone.key) = {
          "management_group_resource_ids"     = module.alz.management_group_resource_ids
          "policy_assignment_resource_ids"    = module.alz.policy_assignment_resource_ids
          "policy_definition_resource_ids"    = module.alz.policy_definition_resource_ids
          "policy_set_definition_resource_ids" = module.alz.policy_set_definition_resource_ids
          "role_definition_resource_ids"      = module.alz.role_definition_resource_ids
          "policy_assignment_identity_ids"    = module.alz.policy_assignment_identity_ids
        }
      }
    )
  )
  sensitive = true
}

output "custom_landing_zones" {
  value = local.custom_landing_zones
}