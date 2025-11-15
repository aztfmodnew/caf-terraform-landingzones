# Azure Cloud Adoption Framework - Terraform Landing Zones

[![Maintained by aztfmodnew](https://img.shields.io/badge/maintained%20by-aztfmodnew-blue)](https://github.com/aztfmodnew)
[![Terraform Version](https://img.shields.io/badge/terraform-%3E%3D1.6.0-623ce4)](https://www.terraform.io/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

> **Important Notice**: This is an **independent fork and continuation** of the original Microsoft Azure CAF Terraform Landing Zones project, maintained by the aztfmodnew community.

## 📌 About This Fork

This repository represents the **community-maintained continuation** of the Azure Cloud Adoption Framework (CAF) Landing Zones for Terraform. After Microsoft announced the deprecation of the original repository in favor of Azure Verified Modules (AVM), the aztfmodnew community has taken ownership to:

✅ **Continue active development and maintenance**
✅ **Provide bug fixes and security updates**
✅ **Add new Azure service support**
✅ **Maintain backward compatibility**
✅ **Support enterprise-grade deployments**

### Migration from Original Repository

If you're migrating from `azure/caf-terraform-landingzones` or `aztfmod/caf-terraform-landingzones`, this fork maintains full compatibility with your existing deployments.

**Key Differences:**
- ✅ **Actively maintained** (vs. deprecated original)
- ✅ **Updated provider versions** (azurerm >= 4.0, azurecaf >= 1.2.28)
- ✅ **Latest Terraform version support** (>= 1.6.0)
- ✅ **Security-first approach** with enabled pre-commit hooks
- ✅ **Enhanced documentation and examples**

---

## 🚀 Quick Start

### Prerequisites

- **Terraform**: >= 1.6.0
- **Azure CLI**: Latest version
- **Rover**: >= 1.7.0 (or use Docker container)
- **Azure Subscription**: With appropriate permissions

### Basic Deployment

#### 1. Deploy Launchpad (Level 0)

The launchpad bootstraps your environment with secure remote state storage:

```bash
# Simple scenario for learning and demonstration
rover -lz /tf/caf/caf_launchpad \
    -launchpad \
    -var-folder /tf/caf/caf_launchpad/scenario/100 \
    -parallelism=30 \
    -a apply

# Advanced scenario with Azure AD integration
rover -lz /tf/caf/caf_launchpad \
    -launchpad \
    -var-folder /tf/caf/caf_launchpad/scenario/200 \
    -parallelism=30 \
    -a apply
```

#### 2. Deploy Foundation (Level 1)

```bash
rover -lz /tf/caf/caf_solution \
    -var-folder /tf/caf/caf_solution/scenario/foundations/100-passthrough \
    -tfstate caf_foundations.tfstate \
    -level level1 \
    -parallelism=30 \
    -a apply
```

#### 3. Deploy Networking (Level 2)

```bash
rover -lz /tf/caf/caf_solution \
    -var-folder /tf/caf/caf_solution/scenario/networking/100-single-region-hub \
    -tfstate caf_networking.tfstate \
    -level level2 \
    -parallelism=30 \
    -a apply
```

---

## 📚 Documentation

### Core Concepts

- **[Architecture Overview](Project_Architecture_Blueprint.md)** - Complete architectural blueprint
- **[Getting Started](documentation/getting_started/getting_started.md)** - Detailed setup guide
- **[Delivery](documentation/delivery/delivery_landingzones.md)** - CI/CD integration patterns
- **[Testing](documentation/test/unit_test.md)** - Testing strategies

### Landing Zone Levels

| Level | Purpose | Components |
|-------|---------|------------|
| **Level 0** | Launchpad | Remote state storage, Key Vault, Service Principals |
| **Level 1** | Foundation | Identity, Management, Governance, Policy |
| **Level 2** | Platform | Networking, Shared Services, Connectivity |
| **Level 3** | Applications | Workload-specific resources |
| **Level 4** | Solutions | Complete application stacks |

### Example Scenarios

- **[Foundations](caf_solution/scenario/foundations/)** - Identity and management setup
- **[Networking](caf_solution/scenario/networking/)** - Hub-spoke, Virtual WAN, private connectivity
- **[Add-ons](caf_solution/add-ons/)** - Azure DevOps agents, GitHub runners

---

## 🏗️ Architecture

### Hierarchical Landing Zone Model

```
┌─────────────────────────────────────────────────────────────┐
│  Level 0: Launchpad (Bootstrap)                             │
│  - Remote State Storage                                     │
│  - Key Vault for Secrets                                    │
│  - Service Principals                                       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Level 1: Foundation (Identity & Management)                │
│  - Azure AD Configuration                                   │
│  - Management Groups                                        │
│  - Policies & Governance                                    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Level 2: Platform (Networking & Shared Services)           │
│  - Hub-Spoke / Virtual WAN                                  │
│  - Shared Services (DNS, Bastion, Firewall)                 │
│  - Connectivity                                             │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│  Level 3+: Applications & Solutions                         │
│  - AKS Clusters                                             │
│  - App Services                                             │
│  - Data Platforms                                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔧 Requirements

### Software Requirements

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| Terraform | >= 1.6.0 | Latest |
| Azure CLI | >= 2.50.0 | Latest |
| Rover | >= 1.7.0 | Latest |
| Git | >= 2.30.0 | Latest |

### Provider Requirements

```hcl
terraform {
  required_version = ">= 1.6.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = ">= 1.2.28"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.45.0"
    }
  }
}
```

### Azure Permissions

- **Subscription**: Owner or Contributor + User Access Administrator
- **Azure AD**: Application Administrator (for service principal creation)
- **Management Groups**: Management Group Contributor (if using management groups)

---

## 🛠️ Module Integration

This landing zone solution uses:

- **[terraform-azurerm-caf](https://github.com/aztfmodnew/terraform-azurerm-caf)** - Core CAF module (version 5.7.13+)
- **[terraform-provider-azurecaf](https://github.com/aztfmodnew/terraform-provider-azurecaf)** - CAF naming provider (version 1.2.28+)
- **[rover](https://github.com/aztfmodnew/rover)** - Terraform execution container (version 1.7.0+)

---

## 🔐 Security Best Practices

### Enabled by Default

✅ **Remote State Encryption** - All state files encrypted in Azure Storage
✅ **Key Vault Integration** - Secrets stored securely in Azure Key Vault
✅ **Managed Identities** - Service principals with least privilege
✅ **Network Isolation** - Private endpoints and service endpoints
✅ **Diagnostic Logging** - Comprehensive audit trails
✅ **Pre-commit Hooks** - Code quality and security validation

### Security Checklist

- [ ] Enable Azure Policy for governance
- [ ] Configure diagnostic settings for all resources
- [ ] Implement Network Security Groups (NSGs)
- [ ] Use private endpoints for PaaS services
- [ ] Enable Azure Defender for Cloud
- [ ] Configure Key Vault access policies
- [ ] Implement RBAC with least privilege
- [ ] Enable multi-factor authentication

---

## 📊 Monitoring & Operations

### Built-in Observability

- **Log Analytics**: Centralized logging for all resources
- **Application Insights**: Application performance monitoring
- **Azure Monitor**: Metrics and alerts
- **Diagnostic Settings**: Resource-level diagnostics

### Key Metrics to Monitor

- Resource deployment success rate
- State file access patterns
- Policy compliance status
- Cost trends and anomalies
- Security alerts and incidents

---

## 🤝 Contributing

We welcome contributions from the community!

### How to Contribute

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Clone the repository
git clone https://github.com/aztfmodnew/caf-terraform-landingzones.git
cd caf-terraform-landingzones

# Install pre-commit hooks
pre-commit install

# Run validation
pre-commit run --all-files
```

### Coding Standards

- Follow [Terraform style conventions](https://www.terraform.io/language/syntax/style)
- Use meaningful variable names
- Add comments for complex logic
- Update documentation for new features
- Write tests for new modules

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🆘 Support

### Community Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/aztfmodnew/caf-terraform-landingzones/issues)
- **Discussions**: [Ask questions and share ideas](https://github.com/aztfmodnew/caf-terraform-landingzones/discussions)
- **Documentation**: [Browse the docs](documentation/)

### Commercial Support

For enterprise support, training, or consulting services, please contact the maintainers.

---

## 📖 Additional Resources

### Microsoft Documentation

- [Azure Cloud Adoption Framework](https://docs.microsoft.com/azure/cloud-adoption-framework/)
- [Azure Landing Zones](https://docs.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Azure Verified Modules](https://aka.ms/avm) - Microsoft's new direction

### Community Resources

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure Architecture Center](https://docs.microsoft.com/azure/architecture/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

---

## 🏆 Acknowledgments

This project builds upon the excellent work of:

- Microsoft Azure CAF Team - Original landing zone design
- aztfmod Community - Foundation modules and patterns
- Terraform Community - Best practices and tooling

---

## 🚦 Project Status

**Status**: 🟢 **Actively Maintained**

- ✅ Regular updates and bug fixes
- ✅ New Azure service support
- ✅ Community-driven development
- ✅ Enterprise production ready

**Last Updated**: November 2025
**Maintainer**: aztfmodnew Community
