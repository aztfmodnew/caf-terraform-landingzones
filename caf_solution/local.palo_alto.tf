locals {
  palo_alto = merge(
    var.palo_alto,
    {
      cloudngfws = var.palo_alto_cloudngfws
    }
  )
}
