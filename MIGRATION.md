# Migration Guide - aztfmodnew Fork

This document provides comprehensive guidance for migrating to the **aztfmodnew fork** of the Azure CAF Terraform Landing Zones.

## Table of Contents

- [Overview](#overview)
- [Migration Scenarios](#migration-scenarios)
- [Pre-Migration Checklist](#pre-migration-checklist)
- [Migration Steps](#migration-steps)
- [Post-Migration Validation](#post-migration-validation)
- [Rollback Plan](#rollback-plan)
- [Troubleshooting](#troubleshooting)

---

## Overview

### Why Migrate?

The original Microsoft Azure CAF Terraform Landing Zones repository was deprecated in 2024, with Microsoft recommending migration to Azure Verified Modules (AVM). The **aztfmodnew community fork** provides:

✅ **Continued Development** - Active maintenance and new features
✅ **Bug Fixes** - Regular security and bug fixes
✅ **Backward Compatibility** - Drop-in replacement for existing deployments
✅ **Community Support** - Active community-driven support
✅ **Updated Dependencies** - Latest Terraform and provider versions

### What Changed?

| Component | Original | aztfmodnew Fork | Impact |
|-----------|----------|-----------------|--------|
| **Repository** | `azure/caf-terraform-landingzones` or `aztfmod/caf-terraform-landingzones` | `aztfmodnew/caf-terraform-landingzones` | Low - Same structure |
| **Terraform Version** | >= 1.3.5 | >= 1.6.0 | Medium - Requires update |
| **azurecaf Provider** | ~> 1.2.0 | ~> 1.2.28 | Low - Compatible |
| **random Provider** | ~> 3.5.0 | ~> 3.6.0 | Low - Compatible |
| **external Provider** | ~> 2.2.0 | ~> 2.3.0 | Low - Compatible |
| **null Provider** | ~> 3.1.0 | ~> 3.2.0 | Low - Compatible |
| **tls Provider** | ~> 3.1.0 | ~> 4.0.0 | Low - Compatible |
| **Rover Image** | 1.6.6-2401.0402 | 1.7.0-2411.0101 | Low - Compatible |
| **CAF Module** | 5.7.13 | 5.7.15 | Low - Compatible |

---

## Migration Scenarios

### Scenario 1: Greenfield Deployment (New Environment)

**Best For**: New Azure environments, POCs, learning

**Steps**:
1. Clone the aztfmodnew repository
2. Follow the [Quick Start guide](README.md#-quick-start)
3. Deploy launchpad and landing zones

**Estimated Time**: 2-4 hours

---

### Scenario 2: Brownfield Migration (Existing Deployment)

**Best For**: Production environments with existing infrastructure

**Steps**: See [Detailed Migration Steps](#migration-steps) below

**Estimated Time**: 4-8 hours (depending on complexity)

---

### Scenario 3: CI/CD Pipeline Migration

**Best For**: Automated deployments using Azure DevOps, GitHub Actions, or Terraform Cloud

**Additional Steps**:
- Update pipeline references
- Update Rover image versions
- Test pipeline in non-production

**Estimated Time**: 2-4 hours

---

## Pre-Migration Checklist

### Environment Assessment

- [ ] **Document Current State**
  - List all deployed landing zones (Level 0, 1, 2, 3+)
  - Document custom modules and modifications
  - Identify dependencies between landing zones
  - Note any custom tfvars or configurations

- [ ] **Version Check**
  - Current Terraform version: ___________
  - Current azurerm provider version: ___________
  - Current CAF module version: ___________
  - Current Rover version: ___________

- [ ] **Backup Critical Data**
  - Export all Terraform state files
  - Document Key Vault secrets
  - Export Azure AD configurations
  - Backup custom scripts and automations

### Tool Requirements

- [ ] Terraform >= 1.6.0 installed
- [ ] Azure CLI >= 2.50.0 installed
- [ ] Git >= 2.30.0 installed
- [ ] Access to Azure subscription with Owner/Contributor permissions
- [ ] Access to Azure AD with Application Administrator role (if needed)

### Testing Environment

- [ ] Create non-production test environment
- [ ] Deploy current version in test environment
- [ ] Verify all functionality in test environment
- [ ] Document test results

---

## Migration Steps

### Phase 1: Preparation (Day 1)

#### Step 1: Clone and Review New Repository

```bash
# Clone aztfmodnew fork
git clone https://github.com/aztfmodnew/caf-terraform-landingzones.git
cd caf-terraform-landingzones

# Review changes
git log --oneline --since="2024-01-01"

# Check current version
cat CHANGELOG.md | head -20
```

#### Step 2: Update Local Terraform Version

```bash
# Check current version
terraform version

# If < 1.6.0, update Terraform
# For Linux/macOS:
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify
terraform version
```

#### Step 3: Compare Configuration Files

```bash
# Compare your current deployment with new version
diff -r /path/to/your/current/caf_launchpad ./caf_launchpad/

# Pay special attention to:
# - main.tf (provider versions)
# - landingzone.tf (module version)
# - variables.tf (new variables)
```

#### Step 4: Update Provider Versions

In your **current deployment**, update `main.tf` files:

```hcl
# caf_launchpad/main.tf
# caf_solution/main.tf

terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"  # Updated
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0"  # Updated
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"  # Updated
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0.0"  # Updated
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~> 1.2.28"  # Updated
    }
  }
  required_version = ">= 1.6.0"  # Updated
}
```

### Phase 2: Test in Non-Production (Day 1-2)

#### Step 5: Deploy to Test Environment

```bash
# Set test environment variables
export ARM_SUBSCRIPTION_ID="<test-subscription-id>"
export ARM_TENANT_ID="<tenant-id>"

# Login to Azure
az login

# Test launchpad deployment
cd caf_launchpad
terraform init -upgrade
terraform plan -var-folder=./scenario/100 -var-file=test.tfvars
terraform apply -var-folder=./scenario/100 -var-file=test.tfvars

# Test solution deployment
cd ../caf_solution
terraform init -upgrade
terraform plan -var-folder=./scenario/foundations/100-passthrough
terraform apply -var-folder=./scenario/foundations/100-passthrough
```

#### Step 6: Validate Test Deployment

```bash
# Check resources
az resource list --output table

# Verify state files
az storage blob list \
  --account-name <storage-account> \
  --container-name tfstate \
  --output table

# Test functionality
# - Verify networking connectivity
# - Check Key Vault access
# - Validate diagnostic logs
# - Test RBAC assignments
```

### Phase 3: Production Migration (Day 3)

#### Step 7: Create Migration Plan

Document the migration order:

```
1. Level 0 (Launchpad) - Storage, Key Vault, Service Principals
2. Level 1 (Foundation) - Identity, Management, Governance
3. Level 2 (Platform) - Networking, Shared Services
4. Level 3+ (Applications) - Workloads
```

#### Step 8: Backup Production State

```bash
# Backup all state files
export STORAGE_ACCOUNT="<your-tfstate-storage>"
export CONTAINER_NAME="tfstate"

# Download all state files
az storage blob download-batch \
  --account-name $STORAGE_ACCOUNT \
  --source $CONTAINER_NAME \
  --destination ./state-backup-$(date +%Y%m%d) \
  --pattern "*.tfstate"

# Backup Key Vault secrets
az keyvault secret list --vault-name <vault-name> --output json > keyvault-backup-$(date +%Y%m%d).json
```

#### Step 9: Update Production Launchpad

```bash
# Navigate to your current production launchpad
cd /path/to/production/caf_launchpad

# Update main.tf with new provider versions
# (as shown in Step 4)

# Initialize with upgrade
terraform init -upgrade

# Plan and review changes
terraform plan -out=launchpad-upgrade.tfplan

# Review the plan carefully
terraform show launchpad-upgrade.tfplan

# Apply if no infrastructure changes (should only be provider upgrades)
terraform apply launchpad-upgrade.tfplan
```

#### Step 10: Update Production Solution

```bash
# Navigate to solution
cd /path/to/production/caf_solution

# Update main.tf and landingzone.tf
# Update module version to 5.7.15 in landingzone.tf

# Initialize with upgrade
terraform init -upgrade

# Plan and review
terraform plan -var-folder=<your-scenario> -out=solution-upgrade.tfplan

# Apply
terraform apply solution-upgrade.tfplan
```

### Phase 4: CI/CD Migration (Day 4)

#### Step 11: Update CI/CD Pipelines

**For GitHub Actions:**

```yaml
# .github/workflows/deploy-landingzone.yml

container:
  image: aztfmod/rover:1.7.0-2411.0101  # Updated
  options: --user 0

steps:
  - uses: actions/checkout@v4  # Updated from v3
```

**For Azure DevOps:**

```yaml
# azure-pipelines.yml

container:
  image: aztfmod/rover:1.7.0-2411.0101  # Updated
```

**For Terraform Cloud:**

Update workspace Terraform version to >= 1.6.0 in settings.

#### Step 12: Test Pipeline

```bash
# Trigger test pipeline run
# - Use non-production environment
# - Validate all stages
# - Check for errors
# - Verify deployed resources
```

---

## Post-Migration Validation

### Validation Checklist

- [ ] **Infrastructure Validation**
  - [ ] All resources deployed successfully
  - [ ] No unexpected changes in Terraform state
  - [ ] Resource groups in correct regions
  - [ ] Tags applied correctly
  - [ ] Diagnostic settings active

- [ ] **Networking Validation**
  - [ ] VNet peerings operational
  - [ ] Private endpoints resolving
  - [ ] NSG rules effective
  - [ ] Route tables active
  - [ ] Firewall rules working

- [ ] **Security Validation**
  - [ ] Key Vault access working
  - [ ] Service principals functional
  - [ ] RBAC assignments correct
  - [ ] Managed identities operational
  - [ ] Diagnostic logs flowing

- [ ] **Operations Validation**
  - [ ] CI/CD pipelines executing
  - [ ] Monitoring alerts functional
  - [ ] Backup jobs running
  - [ ] Cost tracking active

### Validation Scripts

```bash
# Validate state consistency
terraform state list

# Check for drift
terraform plan -var-folder=<your-scenario>

# Verify resources
az resource list --tag environment=<your-env> --output table

# Test connectivity
az network vnet peering list \
  --resource-group <rg-name> \
  --vnet-name <vnet-name> \
  --output table
```

---

## Rollback Plan

### Immediate Rollback (Within 1 hour)

If issues arise immediately after migration:

1. **Restore State Files**:
   ```bash
   az storage blob upload-batch \
     --account-name $STORAGE_ACCOUNT \
     --destination $CONTAINER_NAME \
     --source ./state-backup-<date> \
     --overwrite
   ```

2. **Revert Terraform Version**:
   ```bash
   tfenv use 1.3.5
   # or
   terraform version 1.3.5
   ```

3. **Downgrade Providers**:
   Update `main.tf` back to original versions and run:
   ```bash
   terraform init -upgrade
   terraform plan
   ```

### Delayed Rollback (After 1 hour)

If issues discovered later:

1. **Assess Impact**:
   - Identify affected resources
   - Check state file integrity
   - Review error messages

2. **Targeted Fixes**:
   - Fix specific resources
   - Use `terraform import` if needed
   - Manually reconcile state

3. **Document Issues**:
   - Report to aztfmodnew community
   - Create GitHub issue
   - Share lessons learned

---

## Troubleshooting

### Common Issues

#### Issue 1: Provider Version Conflicts

**Symptom**: `Error: Failed to query available provider packages`

**Solution**:
```bash
# Clear provider cache
rm -rf .terraform/
rm .terraform.lock.hcl

# Reinitialize
terraform init -upgrade
```

#### Issue 2: State Lock Errors

**Symptom**: `Error: Error locking state`

**Solution**:
```bash
# Break the lock (use with caution)
terraform force-unlock <lock-id>

# Or wait for lock to expire (usually 20 minutes)
```

#### Issue 3: Module Version Mismatch

**Symptom**: `Error: Module not compatible with Terraform version`

**Solution**:
```bash
# Update module version in landingzone.tf
# Then reinitialize
terraform init -upgrade
```

#### Issue 4: Authentication Failures

**Symptom**: `Error: building account: could not acquire access token`

**Solution**:
```bash
# Re-login to Azure
az login
az account set --subscription <subscription-id>

# Verify authentication
az account show
```

#### Issue 5: Resource Already Exists

**Symptom**: `Error: A resource with the ID already exists`

**Solution**:
```bash
# Import existing resource
terraform import <resource-type>.<resource-name> <azure-resource-id>

# Or remove from state and let Terraform recreate
terraform state rm <resource-address>
```

### Getting Help

1. **Community Support**:
   - GitHub Issues: https://github.com/aztfmodnew/caf-terraform-landingzones/issues
   - GitHub Discussions: https://github.com/aztfmodnew/caf-terraform-landingzones/discussions

2. **Documentation**:
   - README: [README.md](README.md)
   - Architecture: [Project_Architecture_Blueprint.md](Project_Architecture_Blueprint.md)
   - Examples: [caf_solution/scenario/](caf_solution/scenario/)

3. **Commercial Support**:
   - Contact maintainers for enterprise support options

---

## Migration Timeline Template

### Week 1: Planning and Preparation
- Day 1-2: Assessment and documentation
- Day 3-4: Tool setup and testing environment
- Day 5: Team training and review

### Week 2: Test Migration
- Day 1-2: Deploy test environment
- Day 3-4: Validation and testing
- Day 5: Fix issues and refine plan

### Week 3: Production Migration
- Day 1: Final review and approval
- Day 2: Launchpad migration
- Day 3: Foundation migration
- Day 4: Platform migration
- Day 5: Application migration

### Week 4: Validation and Stabilization
- Day 1-2: Comprehensive validation
- Day 3-4: Monitoring and optimization
- Day 5: Documentation and handoff

---

## Success Criteria

Migration is considered successful when:

✅ All Terraform modules updated to >= 1.6.0
✅ All providers updated to latest versions
✅ All landing zones deployed without errors
✅ No drift detected in Terraform state
✅ All resources operational and accessible
✅ CI/CD pipelines executing successfully
✅ Monitoring and alerting functional
✅ Team trained on new version
✅ Documentation updated
✅ Rollback plan tested and verified

---

## Appendix

### A. Provider Version Matrix

| Provider | Old Version | New Version | Breaking Changes |
|----------|-------------|-------------|------------------|
| azurerm | 3.x | 4.0+ | Yes - See provider changelog |
| azurecaf | 1.2.0 | 1.2.28 | No |
| random | 3.5.0 | 3.6.0 | No |
| external | 2.2.0 | 2.3.0 | No |
| null | 3.1.0 | 3.2.0 | No |
| tls | 3.1.0 | 4.0.0 | Minor - Certificate handling |

### B. Terraform Version Features

New features in Terraform 1.6.0 used by aztfmodnew:

- Enhanced type constraints
- Improved error messages
- Better state file handling
- Performance improvements

### C. Additional Resources

- [Terraform 1.6.0 Release Notes](https://github.com/hashicorp/terraform/releases/tag/v1.6.0)
- [Azure Provider 4.0 Upgrade Guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide)
- [Azure CAF Documentation](https://docs.microsoft.com/azure/cloud-adoption-framework/)

---

**Last Updated**: November 2025
**Document Version**: 1.0
**Maintained by**: aztfmodnew Community
