
provider "azurerm" {
  partner_id = "ca4078f8-9bc4-471b-ab5b-3af6b86a42c8"
  # partner identifier for CAF Terraform landing zones.
  features {
    api_management {
      purge_soft_delete_on_destroy = try(var.provider_azurerm_features_api_management.purge_soft_delete_on_destroy, null)
      recover_soft_deleted         = try(var.provider_azurerm_features_api_management.recover_soft_deleted, null)
    }
    app_configuration {
      purge_soft_delete_on_destroy = try(var.provider_azurerm_features_app_configuration.purge_soft_delete_on_destroy, null)
      recover_soft_deleted         = try(var.provider_azurerm_features_app_configuration.recover_soft_deleted, null)
    }
    application_insights {
      disable_generated_rule = try(var.provider_azurerm_features_application_insights.disable_generated_rule, null)
    }
    cognitive_account {
      purge_soft_delete_on_destroy = var.provider_azurerm_features_cognitive_account.purge_soft_delete_on_destroy
    }
    key_vault {
      purge_soft_delete_on_destroy                            = try(var.provider_azurerm_features_keyvault.purge_soft_delete_on_destroy, false)
      purge_soft_deleted_certificates_on_destroy              = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_certificates_on_destroy, null)
      purge_soft_deleted_keys_on_destroy                      = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_keys_on_destroy, null)
      purge_soft_deleted_secrets_on_destroy                   = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_secrets_on_destroy, null)
      purge_soft_deleted_hardware_security_modules_on_destroy = try(var.provider_azurerm_features_keyvault.purge_soft_deleted_hardware_security_modules_on_destroy, null)
      recover_soft_deleted_certificates                       = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_certificates, null)
      recover_soft_deleted_key_vaults                         = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_key_vaults, true)
      recover_soft_deleted_keys                               = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_keys, null)
      recover_soft_deleted_secrets                            = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_secrets, null)
    }
    log_analytics_workspace {
      permanently_delete_on_destroy = try(var.provider_azurerm_features_log_analytics_workspace.permanently_delete_on_destroy, null)
    }
    managed_disk {
      expand_without_downtime = try(var.provider_azurerm_features_managed_disk.expand_without_downtime, null)
    }
    resource_group {
      prevent_deletion_if_contains_resources = var.provider_azurerm_features_resource_group.prevent_deletion_if_contains_resources
    }
    template_deployment {
      delete_nested_items_during_deletion = var.provider_azurerm_features_template_deployment.delete_nested_items_during_deletion
    }
    virtual_machine {
      delete_os_disk_on_deletion     = try(var.provider_azurerm_features_virtual_machine.delete_os_disk_on_deletion, null)
      graceful_shutdown              = try(var.provider_azurerm_features_virtual_machine.graceful_shutdown, true)
      skip_shutdown_and_force_delete = try(var.provider_azurerm_features_virtual_machine.skip_shutdown_and_force_delete, null)
    }
    virtual_machine_scale_set {
      force_delete                  = try(var.provider_azurerm_features_virtual_machine_scale_set.force_delete, false)
      roll_instances_when_required  = try(var.provider_azurerm_features_virtual_machine_scale_set.roll_instances_when_required, null)
      scale_to_zero_before_deletion = try(var.provider_azurerm_features_virtual_machine_scale_set.scale_to_zero_before_deletion, null)
    }
  }
}

provider "kubernetes" {
  host                   = local.k8sconfigs[var.aks_cluster_key].host
  username               = local.k8sconfigs[var.aks_cluster_key].username
  password               = local.k8sconfigs[var.aks_cluster_key].password
  client_certificate     = local.k8sconfigs[var.aks_cluster_key].client_certificate
  client_key             = local.k8sconfigs[var.aks_cluster_key].client_key
  cluster_ca_certificate = local.k8sconfigs[var.aks_cluster_key].cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = local.k8sconfigs[var.aks_cluster_key].host
    username               = local.k8sconfigs[var.aks_cluster_key].username
    password               = local.k8sconfigs[var.aks_cluster_key].password
    client_certificate     = local.k8sconfigs[var.aks_cluster_key].client_certificate
    client_key             = local.k8sconfigs[var.aks_cluster_key].client_key
    cluster_ca_certificate = local.k8sconfigs[var.aks_cluster_key].cluster_ca_certificate
  }
}

locals {
  k8sconfigs = {
    for key, value in var.aks_clusters : key => {
      host                   = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.host : data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.host
      username               = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.username : data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.username
      password               = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.password : data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.password
      client_certificate     = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.client_certificate) : base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.client_certificate)
      client_key             = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.client_key) : base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.client_key)
      cluster_ca_certificate = local.remote.aks_clusters[value.lz_key][value.key].enable_rbac ? base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_admin_config.0.cluster_ca_certificate) : base64decode(data.azurerm_kubernetes_cluster.kubeconfig[key].kube_config.0.cluster_ca_certificate)
    }
  }
}

# Get kubeconfig from AKS clusters
data "azurerm_kubernetes_cluster" "kubeconfig" {
  for_each = var.aks_clusters

  name                = local.remote.aks_clusters[each.value.lz_key][each.value.key].cluster_name
  resource_group_name = local.remote.aks_clusters[each.value.lz_key][each.value.key].resource_group_name
}