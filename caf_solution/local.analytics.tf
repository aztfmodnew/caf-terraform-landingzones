locals {
  analytics = merge(
    var.analytics,
    {
      fabric_capacities = var.fabric_capacities
    }
  )
}
