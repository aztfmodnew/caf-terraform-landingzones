locals {
  chaos_studio = merge(
    var.chaos_studio,
    {
      chaos_studio_capabilities = var.chaos_studio_capabilities
      chaos_studio_experiments  = var.chaos_studio_experiments
      chaos_studio_targets      = var.chaos_studio_targets
    }
  )
}
