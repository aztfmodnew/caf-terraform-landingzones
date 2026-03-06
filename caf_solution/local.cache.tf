locals {
  cache = merge(
    var.cache,
    {
      managed_redis = var.managed_redis
    }
  )
}
