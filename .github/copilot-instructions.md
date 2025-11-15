# Azure CAF Terraform Landing Zones - AI Coding Agent Guide

> **Community Fork**: This is an actively maintained fork by aztfmodnew, continuing Microsoft's deprecated Azure CAF Landing Zones project.

---

## 🎯 Repository Purpose

This repository implements **hierarchical Azure landing zones** using Terraform following the Cloud Adoption Framework (CAF). It orchestrates infrastructure across multiple levels (L0-L4) with secure state management, modular design, and enterprise governance patterns.

**Key Technologies:**
- **Terraform** >= 1.6.0 with azurerm, azurecaf, azuread providers
- **Rover** - Docker-based Terraform execution environment (1.7.0+)
- **CAF Module** - Core infrastructure module (aztfmodnew/caf v4.44.0+)
  - **Terraform Registry**: https://registry.terraform.io/modules/aztfmodnew/caf/azurerm/latest
  - **Always use the latest compatible version** from the registry
- **Remote State** - Azure Storage backend with state federation

---

## 🏗️ Architecture: Hierarchical Landing Zone Levels

### Level Hierarchy (Critical Concept)

```
Level 0 (Launchpad)    → Bootstrap: Remote state storage, Key Vault, Service Principals
    ↓ (dependencies)
Level 1 (Foundation)   → Identity, Management Groups, Policies, Governance
    ↓
Level 2 (Platform)     → Networking (Hub-Spoke/vWAN), Shared Services, Connectivity
    ↓
Level 3+ (Workloads)   → Applications, AKS, Data Platforms, Solutions
```

**Dependency Flow:**
- Higher levels ALWAYS reference lower levels via `tfstates` configuration
- Level 0 (launchpad) has NO dependencies (self-contained)
- Each level stores its state in the launchpad's storage account
- Remote state federation enables cross-level resource references

---

## 📁 Repository Structure

```
caf-terraform-landingzones/
├── caf_launchpad/              # Level 0 bootstrap
│   ├── main.tf                 # Provider configuration
│   ├── landingzone.tf          # CAF module invocation
│   ├── local.remote_tfstates.tf # Remote state data sources
│   └── scenario/
│       ├── 100/                # Simple scenario (demo/POC)
│       └── 200/                # Advanced (Azure AD integration)
├── caf_solution/               # Level 1-4 deployments
│   ├── main.tf                 # Provider configuration
│   ├── landingzone.tf          # CAF module invocation
│   ├── local.remote_tfstates.tf # Remote state federation
│   ├── scenario/
│   │   ├── foundations/        # Level 1 scenarios
│   │   └── networking/         # Level 2 scenarios
│   └── add-ons/                # Optional extensions
│       ├── azure_devops_agent/
│       ├── aks_applications/
│       └── databricks_v1/
├── templates/                  # Jinja2 templates for code generation
└── documentation/              # Getting started guides
```

---

## 🔑 Critical Concepts

### 1. The `landingzone` Variable (State Orchestration)

**Every deployment MUST define this variable** - it controls state backend and dependency resolution:

```hcl
# Example: Level 2 networking referencing Level 0 launchpad
landingzone = {
  backend_type        = "azurerm"              # State backend type
  global_settings_key = "launchpad"            # Root dependency key
  level               = "level2"               # Current deployment level
  key                 = "caf_networking"       # Unique state identifier
  tfstates = {                                 # Dependencies map
    launchpad = {
      level   = "lower"                        # Dependency level
      tfstate = "caf_launchpad.tfstate"       # State file name
    }
    foundations = {
      level   = "current"                      # Same-level dependency
      tfstate = "caf_foundations.tfstate"
    }
  }
}
```

**How It Works:**
- `tfstates` map defines which remote states to read
- `level: "lower"` reads from launchpad storage account
- `level: "current"` reads from same storage account
- Data is accessed via `data.terraform_remote_state.remote[key].outputs`

### 2. Remote State Federation Pattern

**File Pattern:** `local.remote_tfstates.tf` in each landing zone

```hcl
# Pattern for reading remote state
data "terraform_remote_state" "remote" {
  for_each = try(var.landingzone.tfstates, {})
  
  backend = try(each.value.backend_type, "azurerm")
  config = {
    storage_account_name = local.landingzone[each.value.level].storage_account_name
    container_name       = local.landingzone[each.value.level].container_name
    resource_group_name  = local.landingzone[each.value.level].resource_group_name
    subscription_id      = var.tfstate_subscription_id
    key                  = each.value.tfstate
  }
}

# Accessing remote outputs
locals {
  global_settings = data.terraform_remote_state.remote["launchpad"].outputs.objects["launchpad"].global_settings
  vnets = {
    for key, value in try(var.landingzone.tfstates, {}) : 
      key => merge(try(data.terraform_remote_state.remote[key].outputs.objects[key].vnets, {}))
  }
}
```

**Key Insight:** All cross-level references flow through `local.remote` object passed to CAF module.

### 3. CAF Module Integration Pattern

**File:** `landingzone.tf` (consistent across launchpad and solution)

```hcl
module "launchpad" {  # or "solution" for caf_solution
  source  = "aztfmodnew/caf/azurerm"
  version = "4.44.0"  # Always check https://registry.terraform.io/modules/aztfmodnew/caf/azurerm/latest for the latest version
  
  # Core parameters
  global_settings             = local.global_settings
  remote_objects              = local.remote          # ← Remote state outputs
  current_landingzone_key     = var.landingzone.key
  tenant_id                   = var.tenant_id
  
  # Resource declarations (passed from variables/locals)
  resource_groups             = var.resource_groups
  keyvaults                   = var.keyvaults
  storage_accounts            = var.storage_accounts
  
  # Nested objects for complex services
  networking = {
    vnets                            = try(var.networking.vnets, var.vnets)
    network_security_group_definition = try(var.networking.network_security_group_definition, {})
    private_dns                      = try(var.networking.private_dns, {})
  }
  
  diagnostics = {
    diagnostics_definition   = try(var.diagnostics.diagnostics_definition, {})
    diagnostics_destinations = try(var.diagnostics.diagnostics_destinations, {})
  }
}
```

**Pattern:** Module receives curated `local.remote` with outputs from all dependency levels.

---

## 🚀 Essential Developer Workflows

### Deploy Landing Zones with Rover

**Rover CLI Pattern:**
```bash
# Pattern: rover -lz <path> -var-folder <config> -level <level> -tfstate <name> -a <action>

# 1. Deploy Level 0 (Launchpad) - ALWAYS FIRST
rover -lz /tf/caf/caf_launchpad \
  -launchpad \
  -var-folder /tf/caf/caf_launchpad/scenario/100 \
  -level level0 \
  -parallelism=30 \
  -a apply

# 2. Deploy Level 1 (Foundation)
rover -lz /tf/caf/caf_solution \
  -var-folder /tf/caf/caf_solution/scenario/foundations/100-passthrough \
  -tfstate caf_foundations.tfstate \
  -level level1 \
  -parallelism=30 \
  -a apply

# 3. Deploy Level 2 (Networking)
rover -lz /tf/caf/caf_solution \
  -var-folder /tf/caf/caf_solution/scenario/networking/100-single-region-hub \
  -tfstate caf_networking.tfstate \
  -level level2 \
  -parallelism=30 \
  -a apply
```

**Key Flags:**
- `-lz`: Landing zone path (caf_launchpad or caf_solution)
- `-var-folder`: Configuration folder containing `.tfvars` files
- `-tfstate`: State file name (stored in launchpad storage)
- `-level`: Landing zone level (level0, level1, level2, level3)
- `-launchpad`: Special flag for Level 0 bootstrapping
- `-a`: Terraform action (plan, apply, destroy)
- `-parallelism=30`: Increase parallel resource operations

**Cross-Subscription Deployments:**
```bash
# Deploy to different subscription than where tfstate is stored
rover -lz /tf/caf/caf_solution \
  -tfstate_subscription_id <STATE_SUB_ID> \
  -target_subscription <TARGET_SUB_ID> \
  -tfstate caf_networking.tfstate \
  -level level2 \
  -a apply
```

### Local Development (Without Rover)

```bash
# From caf_solution or caf_launchpad directory
terraform init \
  -backend-config="storage_account_name=<STORAGE>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=<TFSTATE_NAME>.tfstate"

terraform plan -var-file="scenario/100/configuration.tfvars"
terraform apply -var-file="scenario/100/configuration.tfvars"
```

### GitHub Actions Workflow Pattern

```yaml
# .github/workflows/landingzones-tf100.yml
jobs:
  launchpad:
    runs-on: ubuntu-latest
    container:
      image: aztfmod/rover:1.7.0-2411.0101  # Always use versioned image
      options: --user 0
    
    steps:
      - uses: actions/checkout@v4
      - name: Login Azure
        run: |
          az login --service-principal -u '${{ env.ARM_CLIENT_ID }}' \
            -p '${{ env.ARM_CLIENT_SECRET }}' --tenant '${{ env.ARM_TENANT_ID }}'
      
      - name: Deploy Launchpad
        run: |
          /tf/rover/rover.sh -lz ${GITHUB_WORKSPACE}/caf_launchpad -a apply \
            -var-folder ${GITHUB_WORKSPACE}/caf_launchpad/scenario/100 \
            -level level0 -launchpad -parallelism=30 \
            --environment ${{ github.run_id }}
```

---

## 🛠️ Common Tasks and Patterns

### Creating a New Scenario

**Structure:**
```
caf_solution/scenario/
└── my_category/
    └── 100-my-scenario/
        ├── landingzone.tfvars          # REQUIRED: State configuration
        ├── configuration.tfvars        # REQUIRED: Resource definitions
        ├── global_settings.tfvars      # Optional: Override globals
        └── README.md                   # Document scenario purpose
```

**Minimal landingzone.tfvars:**
```hcl
landingzone = {
  backend_type        = "azurerm"
  global_settings_key = "launchpad"
  level               = "level1"  # Adjust based on scenario
  key                 = "my_scenario"
  tfstates = {
    launchpad = {
      level   = "lower"
      tfstate = "caf_launchpad.tfstate"
    }
  }
}
```

### Reading Remote State Outputs

**Pattern:** Access via `data.terraform_remote_state.remote[<key>].outputs`

```hcl
# In locals.tf or module calls
locals {
  # Get global settings from launchpad
  global_settings = data.terraform_remote_state.remote[var.landingzone.global_settings_key].outputs.objects[var.landingzone.global_settings_key].global_settings
  
  # Get VNets from networking level
  vnets = merge(
    try(data.terraform_remote_state.remote["networking"].outputs.objects["networking"].vnets, {})
  )
  
  # Get managed identities from foundation
  managed_identities = merge(
    try(data.terraform_remote_state.remote["foundations"].outputs.objects["foundations"].managed_identities, {})
  )
}
```

### Debugging Rover Issues

**Common Problems:**

1. **"No launchpad found"**
   - Ensure Level 0 deployed first: `rover -lz caf_launchpad -launchpad -a apply`
   - Check Azure Storage account exists in subscription

2. **"Cycle error" between levels**
   - Verify `tfstates` map doesn't create circular dependencies
   - Check `level` values: "lower" vs "current" vs "higher"

3. **"State lock errors"**
   - Check for stuck locks: `terraform force-unlock <LOCK_ID>`
   - Or via Azure Portal: Storage Account → Containers → tfstate → Leases

4. **Rover execution logs:**
   ```bash
   # Rover logs are in:
   ${TF_DATA_DIR}/${environment}/${level}/${tfstate}/logs/
   
   # Enable debug mode:
   export TF_LOG=DEBUG
   rover -lz ... -a plan
   ```

---

## 📊 Testing and Validation

### Pre-commit Hooks (Automated Quality Checks)

```bash
# Install hooks
pre-commit install

# Run all checks
pre-commit run --all-files

# Active checks (see .pre-commit-config.yaml):
# - terraform_fmt: Code formatting
# - terraform_validate: Syntax validation
# - terraform_tflint: Linting (uses .tflint.hcl config)
# - terraform_tfsec: Security scanning (MEDIUM+ severity)
# - terraform_docs: Auto-generate documentation
```

**Bypass for Emergencies:**
```bash
git commit --no-verify -m "emergency fix"
```

### Manual Validation

```bash
# Validate Terraform syntax
terraform -chdir=caf_launchpad validate

# Check formatting
terraform -chdir=caf_launchpad fmt -check -recursive

# Security scan
tfsec caf_solution/

# Linting
tflint --config=.tflint.hcl caf_solution/
```

---

## 🔐 Security and Best Practices

### Provider Configuration Patterns

**NEVER hardcode credentials** - Use Azure authentication:

```hcl
# main.tf - Correct pattern
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = try(var.provider_azurerm_features_keyvault.purge_soft_delete_on_destroy, false)
      recover_soft_deleted_key_vaults = try(var.provider_azurerm_features_keyvault.recover_soft_deleted_key_vaults, true)
    }
  }
  # NO subscription_id, client_id, tenant_id - set via environment or Azure CLI
}

# Authentication methods (in order of preference):
# 1. Azure CLI: az login
# 2. Managed Identity (in Azure VMs/containers)
# 3. Service Principal (CI/CD): ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
```

### State Security

- **Encryption:** Azure Storage encryption at rest (enabled by default in launchpad)
- **Access Control:** RBAC on storage account, Key Vault access policies
- **Locking:** Terraform state locking via Azure Storage leases (automatic)
- **Secrets:** Store in Key Vault, reference via data sources (never in .tfvars)

### Deprecated Features to Avoid

```hcl
# ❌ DEPRECATED in azurerm provider
provider "azurerm" {
  skip_provider_registration = true  # Deprecated - remove or comment
  features {
    virtual_machine {
      graceful_shutdown = true  # Deprecated - remove
    }
  }
}

# ✅ CORRECT - Minimal provider config
provider "azurerm" {
  features {}
}
```

---

## 🆘 Troubleshooting Guide

### Issue: Changes not detected between levels

**Cause:** State not refreshed or wrong `level` in tfstates map

**Solution:**
```bash
# Force refresh from remote state
terraform refresh -var-file="scenario/100/configuration.tfvars"

# Verify tfstates configuration
terraform console
> var.landingzone.tfstates
```

### Issue: "Module not found" errors

**Cause:** Terraform not initialized or provider cache issues

**Solution:**
```bash
# Clear cache and reinitialize
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

### Issue: Rover container permissions errors

**Cause:** Docker user permissions or volume mount issues

**Solution:**
```bash
# Run rover with explicit user
docker run --rm -it --user $(id -u):$(id -g) aztfmod/rover:1.7.0-2411.0101 bash

# Or use Rover's built-in commands (automatically handles permissions)
rover login
rover -lz ... -a plan
```

---

## 📚 Key Files Reference

| File | Purpose | When to Modify |
|------|---------|----------------|
| `landingzone.tf` | CAF module invocation | Adding new resource types |
| `main.tf` | Provider configuration | Provider version updates |
| `local.remote_tfstates.tf` | Remote state data sources | Never (standard pattern) |
| `variables.tf` | Input variable definitions | Adding new configuration options |
| `scenario/*/landingzone.tfvars` | State orchestration config | Creating new scenarios |
| `scenario/*/configuration.tfvars` | Resource definitions | Deploying resources |

---

## 🔗 Related Repositories

- **[terraform-azurerm-caf](https://github.com/aztfmodnew/terraform-azurerm-caf)** - Core CAF module (631+ resource types)
  - **Terraform Registry**: https://registry.terraform.io/modules/aztfmodnew/caf/azurerm/latest
- **[terraform-provider-azurecaf](https://github.com/aztfmodnew/terraform-provider-azurecaf)** - Naming provider (CAF-compliant names)
- **[rover](https://github.com/aztfmodnew/rover)** - Terraform execution container

---

## 💡 Pro Tips

1. **Always deploy Level 0 first** - Everything depends on launchpad
2. **Use meaningful tfstate names** - `caf_networking_hub.tfstate`, not `state.tfstate`
3. **Leverage scenario folders** - Don't modify examples, create new scenarios
4. **Test in isolation** - Use separate `-env` flag per test: `--environment dev123`
5. **Document dependencies** - Update `landingzone.tfvars` tfstates map when adding cross-level refs
6. **Version control Rover** - Use specific image tags: `aztfmod/rover:1.7.0-2411.0101`, not `:latest`
7. **Read logs** - Rover logs are in `${TF_DATA_DIR}` (defaults to `/tf/caf`)

---

## ⚠️ Common Mistakes to Avoid

❌ **DON'T:** Deploy Level 1 before Level 0 (launchpad must exist first)
❌ **DON'T:** Hardcode subscription IDs or tenant IDs in .tfvars (use variables/globals)
❌ **DON'T:** Mix `level: "current"` and `level: "lower"` for same dependency
❌ **DON'T:** Commit `.terraform/` or `*.tfstate` files to git (use .gitignore)
❌ **DON'T:** Run `terraform destroy` directly on launchpad (use rover with `-a destroy`)

✅ **DO:** Follow numbered scenario conventions (100-simple, 200-intermediate, 300-advanced)
✅ **DO:** Use try() for optional nested values: `try(var.networking.vnets, {})`
✅ **DO:** Pass `local.remote` to CAF module for cross-level resource access
✅ **DO:** Use `-parallelism=30` for faster deployments
✅ **DO:** Test scenarios in non-production before applying to production

---

**Last Updated:** 2025-11-14
**Maintainer:** aztfmodnew Community
**Documentation:** [README.md](../README.md) | [MIGRATION.md](../MIGRATION.md) | [CONTRIBUTING.md](../CONTRIBUTING.md)
