locals {
  bot = merge(
    var.bot,
    {
      azure_bots = var.azure_bots
    }
  )
}
