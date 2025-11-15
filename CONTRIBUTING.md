# Contributing to Azure CAF Terraform Landing Zones (aztfmodnew)

First off, thank you for considering contributing to the aztfmodnew fork of Azure CAF Terraform Landing Zones! It's people like you that make this project such a great tool for the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Pull Request Process](#pull-request-process)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)

---

## Code of Conduct

This project and everyone participating in it is governed by our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

---

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples** (code snippets, configurations)
- **Describe the behavior you observed and what you expected**
- **Include screenshots** if relevant
- **Include your environment details**:
  - Terraform version
  - Provider versions
  - Rover version
  - Operating system

**Bug Report Template:**

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Deploy landing zone with '...'
2. Run command '...'
3. See error

**Expected behavior**
What you expected to happen.

**Environment:**
- Terraform: [e.g., 1.6.0]
- azurerm provider: [e.g., 4.0.0]
- azurecaf provider: [e.g., 1.2.28]
- Rover: [e.g., 1.7.0-2411.0101]
- OS: [e.g., Ubuntu 22.04]

**Additional context**
Add any other context about the problem.
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description** of the suggested enhancement
- **Provide specific examples** of how it would be used
- **Explain why this enhancement would be useful** to most users
- **List any alternatives** you've considered

### Adding New Features

Want to add a new Azure service or landing zone pattern? Here's how:

1. **Check existing issues/PRs** to avoid duplication
2. **Create an issue** describing the feature
3. **Wait for maintainer feedback** before starting work
4. **Follow the development workflow** (see below)

---

## Development Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR-USERNAME/caf-terraform-landingzones.git
cd caf-terraform-landingzones

# Add upstream remote
git remote add upstream https://github.com/aztfmodnew/caf-terraform-landingzones.git
```

### 2. Create a Branch

```bash
# Update your fork
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-fix-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/changes

### 3. Set Up Development Environment

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install tfsec
curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Verify installations
terraform version  # Should be >= 1.6.0
tflint --version
tfsec --version
pre-commit --version
```

### 4. Make Changes

Follow the [Coding Standards](#coding-standards) below.

### 5. Test Changes

```bash
# Format code
terraform fmt -recursive

# Validate
terraform validate

# Run linting
tflint --recursive

# Run security scan
tfsec .

# Run all pre-commit hooks
pre-commit run --all-files
```

### 6. Commit Changes

Use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
git add .
git commit -m "feat: add support for Azure Container Apps"
git commit -m "fix: resolve state locking issue in launchpad"
git commit -m "docs: update README with new examples"
```

Commit message types:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Build process or auxiliary tool changes

### 7. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## Coding Standards

### Terraform Style

Follow [Terraform style conventions](https://www.terraform.io/language/syntax/style):

```hcl
# ✅ Good
resource "azurerm_resource_group" "example" {
  name     = "rg-example"
  location = "westeurope"
  
  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# ❌ Bad
resource "azurerm_resource_group" "example" {
name="rg-example"
location="westeurope"
tags={environment="dev",managed_by="terraform"}
}
```

### File Organization

```
module/
├── main.tf              # Main resource definitions
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # Provider configuration
├── locals.tf            # Local values
├── data.tf              # Data sources
└── versions.tf          # Terraform and provider versions
```

### Naming Conventions

**Resources:**
```hcl
# Use descriptive names
resource "azurerm_virtual_network" "hub" { ... }  # ✅
resource "azurerm_virtual_network" "vnet1" { ... } # ❌

# Use snake_case
resource "azurerm_resource_group" "main_rg" { ... }  # ✅
resource "azurerm_resource_group" "mainRg" { ... }   # ❌
```

**Variables:**
```hcl
# Use descriptive names
variable "resource_group_name" { ... }  # ✅
variable "rg" { ... }                   # ❌

# Include descriptions and types
variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westeurope"
}
```

**Outputs:**
```hcl
# Use descriptive names
output "virtual_network_id" { ... }  # ✅
output "vnet" { ... }                # ❌
```

### Documentation

**Variables:**
```hcl
variable "enable_diagnostics" {
  description = "Enable diagnostic settings for all resources. When enabled, sends logs to Log Analytics workspace specified in diagnostics_workspace_id."
  type        = bool
  default     = true
}
```

**Complex Resources:**
```hcl
# Add comments for complex logic
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = var.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]

  # Enable DDoS protection for production environments
  ddos_protection_plan {
    id     = var.ddos_protection_plan_id
    enable = var.environment == "prod"
  }
}
```

### Security Best Practices

1. **Never commit secrets**:
   ```hcl
   # ❌ Bad
   client_secret = "super-secret-value"
   
   # ✅ Good
   client_secret = var.client_secret  # Passed via environment or tfvars
   ```

2. **Use try() for optional values**:
   ```hcl
   # ✅ Good - Handles missing values gracefully
   enable_diagnostics = try(var.settings.diagnostics.enabled, true)
   ```

3. **Validate inputs**:
   ```hcl
   variable "location" {
     description = "Azure region"
     type        = string
     
     validation {
       condition     = contains(["westeurope", "northeurope", "eastus"], var.location)
       error_message = "Location must be one of: westeurope, northeurope, eastus."
     }
   }
   ```

---

## Pull Request Process

### PR Checklist

Before submitting, ensure:

- [ ] Code follows the [Coding Standards](#coding-standards)
- [ ] All tests pass (`terraform validate`, `tflint`, `tfsec`)
- [ ] Pre-commit hooks pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated (for significant changes)
- [ ] Examples are provided (for new features)
- [ ] Commit messages follow Conventional Commits
- [ ] PR description explains the change

### PR Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## How Has This Been Tested?
Describe the tests you ran and their results.

## Checklist
- [ ] My code follows the style guidelines
- [ ] I have performed a self-review
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

## Related Issues
Fixes #(issue number)
```

### Review Process

1. **Automated Checks**: GitHub Actions will run automated tests
2. **Code Review**: Maintainers will review your code
3. **Discussion**: Address any feedback or questions
4. **Approval**: Once approved, maintainers will merge

**Expected Timeline:**
- Initial review: Within 2-3 business days
- Follow-up reviews: Within 1-2 business days

---

## Testing Guidelines

### Unit Testing

For new modules or significant changes, include examples that can be tested:

```bash
# Test example deployment
cd examples/your-new-feature/
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy -auto-approve
```

### Integration Testing

For features that interact with Azure:

1. Create test environment
2. Deploy using test configuration
3. Verify resources created correctly
4. Test functionality
5. Clean up resources

### Test Scenarios

**Example Test Plan:**
```markdown
## Test Scenarios

### Scenario 1: Basic Deployment
- Deploy with minimal configuration
- Verify resources created
- Test basic functionality

### Scenario 2: Advanced Configuration
- Deploy with all features enabled
- Test private endpoints
- Test diagnostics
- Test RBAC

### Scenario 3: Multi-Region
- Deploy across multiple regions
- Test replication
- Test failover
```

---

## Documentation

### README Updates

When adding new features:

1. Update main [README.md](README.md) if applicable
2. Create/update module-specific READMEs
3. Add examples with clear instructions
4. Update architecture diagrams if needed

### Example Documentation

Each example should include:

```markdown
# Feature Name Example

## Overview
Brief description of what this example demonstrates.

## Architecture
Diagram or description of deployed resources.

## Prerequisites
- Terraform >= 1.6.0
- Azure subscription
- Required permissions

## Deployment

\`\`\`bash
# Step-by-step instructions
terraform init
terraform plan -var-file="configuration.tfvars"
terraform apply -var-file="configuration.tfvars"
\`\`\`

## Validation
How to verify the deployment succeeded.

## Cleanup

\`\`\`bash
terraform destroy -var-file="configuration.tfvars"
\`\`\`
```

### CHANGELOG Updates

For significant changes, update [CHANGELOG.md](CHANGELOG.md):

```markdown
## [Unreleased]

### Added
- New feature description

### Changed
- Changed behavior description

### Fixed
- Bug fix description

### Deprecated
- Deprecated feature description

### Removed
- Removed feature description
```

---

## Community

### Getting Help

- **GitHub Discussions**: For questions and discussions
- **GitHub Issues**: For bug reports and feature requests
- **Pull Requests**: For code contributions

### Communication Guidelines

- Be respectful and inclusive
- Provide context and examples
- Search existing issues before creating new ones
- Use clear and descriptive titles
- Follow up on your issues/PRs

---

## Recognition

Contributors will be recognized in:
- Release notes
- CHANGELOG.md
- GitHub contributors page

Thank you for contributing to make Azure CAF Terraform Landing Zones better! 🎉

---

**Last Updated**: November 2025
**Maintained by**: aztfmodnew Community
