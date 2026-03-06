locals {
  maintenance = merge(
    var.maintenance,
    {
      maintenance_configuration              = var.maintenance_configuration
      maintenance_assignment_virtual_machine = var.maintenance_assignment_virtual_machine
      maintenance_assignment_dynamic_scope   = var.maintenance_assignment_dynamic_scope
    }
  )
}
