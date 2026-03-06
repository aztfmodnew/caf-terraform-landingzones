# Maintenance
variable "maintenance" {
  description = "Maintenance configuration objects"
  default     = {}
}

variable "maintenance_configuration" {
  default = {}
}

variable "maintenance_assignment_virtual_machine" {
  default = {}
}

variable "maintenance_assignment_dynamic_scope" {
  default = {}
}
