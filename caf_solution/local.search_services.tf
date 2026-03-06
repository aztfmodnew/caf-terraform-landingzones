locals {
  search_services = merge(
    var.search_services,
    {
      search_services = var.azure_search_services
    }
  )
}
