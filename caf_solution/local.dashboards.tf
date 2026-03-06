locals {
  dashboards = merge(
    var.dashboards,
    {
      grafana = var.grafana
    }
  )
}
