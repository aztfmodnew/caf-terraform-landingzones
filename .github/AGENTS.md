# 🤖 Available Agents - caf-terraform-landingzones

This document lists all AI agents available for **landing zone deployments, orchestration, and infrastructure scenarios** in the caf-terraform-landingzones repository.

---

## 🚀 Core Deployment Agents

### **Rover Ignite Orchestrator** (NEW!)
**Purpose:** Automatically generate complete landing zone configuration (L0-L3, 50+ tfvars files) from a single `ignite.yaml` topology definition using Ansible + Jinja2 templating.

**When to use:**
- "Generate L0-L3 configuration for my multi-subscription environment"
- "I have 5 subscriptions (management, connectivity, identity, security, caf); create all tfvars automatically"
- "Set up a production landing zone from scratch in 15 minutes"
- "Update ignite.yaml and regenerate all 50+ config files"

**What it does:**
- Interactive setup via Ansible (prompts for customer name, regions, subscriptions, email)
- Discovers Azure context (tenant_id, subscription_ids, IP whitelist)
- Loads `ignite.yaml` → deployment topology
- Renders 50+ Jinja2 templates with Ansible
- Generates `configuration/level0/*.tfvars`, `level1/*.tfvars`, `level2/*.tfvars`
- Auto-configures state federation (L1-L3 reference L0 outputs)
- Generates firewall rules (1000+ rules from YAML definitions)
- Creates `.github/workflows` for CI/CD
- All files ready for immediate `terraform apply`

**Key inputs (ignite.yaml):**
```yaml
bootstrap:
  deployments:
    platform:
      root:
        region1:
          launchpad: launchpad.yaml
          identity: identity.yaml
          management: management.yaml
      subscriptions:
        management: subscription-guid
        connectivity: subscription-guid
        identity: subscription-guid
        security: subscription-guid
      scale_out_domains:
        region1:
          identity_level2: {prod, nonprod}
          connectivity_virtual_wans: {prod}
          virtual_hubs: {prod, nonprod}
```

**Key outputs:**
```
configuration/
├── level0/
│   └── launchpad.tfvars
├── level1/
│   ├── platform_subscriptions.tfvars
│   ├── identity.tfvars
│   ├── management.tfvars
│   └── alz.tfvars
├── level2/
│   ├── connectivity_virtual_wans_prod.tfvars
│   ├── virtual_hubs_prod.tfvars
│   └── ... (25+ more)
└── .github/workflows/ (ready for deployment)
```

**When NOT to use:**
- Single-subscription dev/test (use scenario-based examples)
- Debugging specific resource configs (use Module Updater instead)
- Learning CAF patterns (use manual scenarios first)

**Advantages over manual configuration:**
| Feature | Ignite | Manual |
|---------|--------|--------|
| **Time to L0-L3** | 15 min | 2-3 hours |
| **Files generated** | 50+ tfvars | Write each manually |
| **Cross-level refs** | Automatic | Manual ID tracking |
| **Subscription coordination** | Automatic | Prone to errors |
| **Firewall rules** | 1000+ auto | Tedious hand-entry |
| **prod/nonprod** | Auto-variants | Duplicate + update |
| **Idempotent updates** | Re-run playbook | Start over |

**Example invocation:**
```
Agent: Rover Ignite Orchestrator
Prompt: "Generate landing zone config for multi-subscription environment with:
- Management subscription
- Connectivity subscription (hub-spoke networking)
- Identity subscription (Azure AD, service principals)
- Security subscription (DDoS, WAF, policies)
- prod and nonprod variants for scale-out domains

Use westeurope and eastus regions"
```

**Related documentation:**
- [Rover Ignite Bootstrap Guide](../../templates/BOOTSTRAP-GUIDE.md) ← Read this first!
- [ansible.yaml orchestrator](../../templates/ansible/ansible.yaml)
- [ignite.yaml example](../../templates/platform/ignite.yaml)
- [Jinja2 resource templates](../../templates/resources/)

---

### **Remote State Orchestrator**
**Purpose:** Manages remote state dependencies, tfstate configuration, and cross-landing-zone references in hierarchical CAF deployments.

**When to use:**
- "Set up state dependencies between Level 1 and Level 0"
- "I'm getting a cycle error in the tfstate configuration"
- "How do I reference outputs from the networking level in the workload level?"

**What it does:**
- Configures `landingzone.tfvars` with correct tfstates map
- Sets up remote state data sources (`local.remote_tfstates.tf`)
- Handles `level` values correctly (lower/current/higher)
- Manages cross-landing-zone references
- Resolves circular dependency issues
- Updates `locals.combined_objects` for service aggregation

**Example invocation:**
```
"Configure state dependencies for a Level 3 workload that needs VNets from Level 2 and identities from Level 1"
```

**Related guidance:** 
- [Copilot Instructions - Remote State Federation](../copilot-instructions.md#2-remote-state-federation-pattern)
- [Dependency Resolution Instructions](.github/instructions/dependency-resolution.instructions.md)

---

### **CAF Orchestrator**
**Purpose:** Coordinates multi-step landing zone workflows by orchestrating level deployments with proper sequencing and dependency management.

**When to use:**
- "Deploy the complete landing zone hierarchy from L0 to L3"
- "What's the sequence for adding a new level?"
- "I need to coordinate networking changes across multiple levels"

**What it does:**
- Sequences deployments: L0 → L1 → L1 → L3 → L4
- Validates dependencies before each step
- Monitors state lock issues and provides recovery steps
- Handles subscription switching for cross-subscription deployments
- Provides rollback strategies
- Tracks output propagation through levels

**Example invocation:**
```
"Deploy Level 0 launchpad, then Level 1 foundations, then Level 2 single-region hub-spoke networking in sequence"
```

---

## 🏗️ Scenario & Configuration Agents

### **ALZ Policy Composer** (NEW!)
**Purpose:** Designs and validates governance composition for ALZ, AMBA, and optional SLZ overlays across multiple landing zones.

**When to use:**
- "Enable AMBA incrementally for selected landing zones"
- "Standardize ALZ policy versions across 10 landing zones"
- "Plan ALZ embedded → external library migration"
- "Review archetype overrides and policy assignment conflicts"

**What it does:**
- Reviews `ignite.yaml` and management group policy settings per landing zone
- Validates ALZ feature flags (`alz_library.source`, `enable_amba`, `enable_slz`)
- Suggests phased rollout strategy (pilot → wave rollout)
- Detects policy overlap/risk areas before apply
- Produces migration checklist for version upgrades

**Example invocation:**
```
"Compose governance for 10 landing zones with ALZ v2.1.0 baseline and AMBA enabled only for prod workloads"
```

**Related files:**
- [Rover Ignite Bootstrap Guide](../../templates/BOOTSTRAP-GUIDE.md)
- [ALZ service template](../../templates/platform/services/alz.yaml)
- [ALZ deployment loader](../../templates/ansible/load_deployments_alz.yaml)

### **Documentation Sync**
**Purpose:** Maintains comprehensive, accurate module and scenario documentation with automated README generation and CHANGELOG tracking.

**When to use:**
- "Update the README for the new networking scenario"
- "Generate documentation for Level 2 deployment"
- "Keep architecture documentation in sync with code changes"

**What it does:**
- Auto-generates README.md from scenario structure
- Updates CHANGELOG.md with changes
- Documents variables and outputs
- Creates architecture diagrams
- Links to related scenarios
- Maintains getting-started guides

**Example invocation:**
```
"Generate comprehensive documentation for caf_solution/scenario/networking/200-multi-region hub-spoke deployment"
```

---

### **Migration Assistant**
**Purpose:** Assists with migrating scenarios to new patterns, refactoring code, and updating deprecated features while maintaining backward compatibility.

**When to use:**
- "Update this Level 1 scenario from CAF v3 to v4"
- "Refactor the networking scenario to use vWAN instead of hub-spoke"
- "Migrate the old scenario structure to the new directory layout"

**What it does:**
- Analyzes old configuration structure
- Maps to new CAF module patterns
- Maintains backward compatibility
- Updates variable references
- Migrates remote state configurations
- Tests scenarios before/after migration
- Documents migration steps

**Example invocation:**
```
"Migrate caf_solution/scenario/networking/100-single-region-hub to use the new hub-spoke module pattern from terraform-azurerm-caf v4.44.0+"
```

---

## 🧪 Validation & Testing Agents

### **Compliance Validator**
**Purpose:** Validates Terraform configurations against CAF standards, Azure best practices, and organizational policies.

**When to use:**
- "Check if this Level 2 scenario follows CAF naming standards"
- "Validate the landingzone.tfvars configuration"
- "Ensure all resource names comply with CAF conventions"

**What it does:**
- Validates CAF naming patterns
- Checks landingzone variable structure
- Confirms tfstate configuration correctness
- Detects hardcoded IDs or credentials
- Verifies dependency graph (no circular refs)
- Reports compliance issues with fixes

**Example invocation:**
```
"Validate caf_solution/scenario/networking/100-single-region-hub against CAF standards"
```

---

## 🔄 Integration & Cross-Repo Agents

### **CAF Orchestrator** (Extended)
**Purpose:** Full orchestration between terraform-azurerm-caf (modules) and caf-terraform-landingzones (deployments).

**When to use:**
- "I updated a module in terraform-azurerm-caf; how does it affect deployments?"
- "Create a module and scenario that works together"

**What it does:**
- Maps module changes to scenario impacts
- Validates module compatibility with deployment scenarios
- Generates compatible scenario configurations
- Tests module + scenario together
- Coordinates version pinning

**Example invocation:**
```
"Create a new App Gateway module in terraform-azurerm-caf and a corresponding Level 3 workload scenario in caf-terraform-landingzones"
```

---

## 📋 Level-Specific Deployment Workflows

### **Level 0 (Launchpad) Deployment**

```bash
# Direct command (no agent needed - simple)
rover -lz caf_launchpad \
  -launchpad \
  -var-folder caf_launchpad/scenario/100 \
  -level level0 -a apply
```

**When to use an agent:**
- "Configure a new launchpad scenario"
- "Migrate launchpad to a different subscription"
- "Update launchpad RBAC and Key Vault policies"

---

### **Level 1 (Foundations) Deployment**

**Agent:** Remote State Orchestrator + CAF Orchestrator

**Typical workflow:**
```
1. Remote State Orchestrator configures tfstate (references L0)
2. CAF Orchestrator deploys foundations
3. Outputs stored in L0's Key Vault
4. L2 can now reference L1 outputs
```

**Example invocation:**
```
"Deploy Level 1 foundations with management groups and Azure AD configuration referencing Level 0 outputs"
```

---

### **Level 2 (Networking) Deployment**

**Agent:** Remote State Orchestrator + CAF Orchestrator

**Typical workflow:**
```
1. Configure state references to L0 (launchpad) and L1 (foundations)
2. Deploy single-region hub-spoke or vWAN
3. Set up private DNS zones
4. Configure network connectivity
```

**Example invocation:**
```
"Deploy Level 2 single-region hub-spoke network with private DNS, NSGs, and route tables referencing Level 0 and 1"
```

---

### **Level 3+ (Workloads) Deployment**

**Agent:** Remote State Orchestrator + CAF Orchestrator + Migration Assistant (if updating)

**Typical workflow:**
```
1. Configure state references (L0, L1, L2, any custom services)
2. Deploy application components
3. Configure managed identities
4. Wire private endpoints to L2 networking
```

**Example invocation:**
```
"Deploy Level 3 AKS workload with managed identities from L1, networking from L2, and state management in L0"
```

---

## 🎓 Common Scenarios & Agent Recommendations

### Scenario 1: Deploy Complete Landing Zone Stack

```
User: "I need to deploy a complete Azure CAF landing zone from scratch"

Step 1: CAF Orchestrator
  └─ Deploy L0 (launchpad) - state, KeyVault, IAM
  
Step 2: Remote State Orchestrator + CAF Orchestrator
  └─ Deploy L1 (foundations) - identity, management groups
  
Step 3: Remote State Orchestrator + CAF Orchestrator
  └─ Deploy L2 (networking) - hub-spoke, private DNS
  
Step 4: Remote State Orchestrator + CAF Orchestrator
  └─ Deploy L3 (workload) - applications, AKS
  
Result: ✅ Fully integrated landing zone
```

---

### Scenario 2: Troubleshoot State Dependency Issues

```
User: "I'm getting a cycle error when deploying Level 2 networking"

Workflow:
1. Remote State Orchestrator analyzes tfstate configuration
2. Identifies circular reference in dependency map
3. Fixes level values (changes "current" to "lower" where needed)
4. Re-deploys successfully
```

---

### Scenario 3: Migrate Existing Infrastructure to CAF

```
User: "I have existing Azure resources; how do I migrate them to CAF?"

Workflow:
1. Migration Assistant analyzes current structure
2. Maps to CAF landing zone levels
3. Creates import scenarios
4. Provides migration steps
5. Tests compatibility
```

---

### Scenario 4: Add New Workload Level

```
User: "I need to add a new application tier (L3 workload) to existing infrastructure"

Workflow:
1. Remote State Orchestrator configures tfstate references (L0, L1, L2)
2. CAF Orchestrator validates dependencies
3. Creates workload scenario
4. Tests integration
5. Deploys to Azure
```

---

## 🔐 Prerequisites & Checks

### Before Deploying Any Level

✅ **MANDATORY Checks:**
```bash
# 1. Verify Azure subscription (CRITICAL)
az account show --query "{subscriptionId:id, name:name, state:state}" -o table

# 2. Confirm you're deploying to the right subscription
# ⚠️ Stop here if subscription is wrong!

# 3. Verify Rover is available (if not using agent)
which rover  # or: docker pull aztfmodnew/rover:1.7.0-2411.0101

# 4. Check terraform is initialized
terraform -v  # version >= 1.6.0
```

---

## 📚 Related Documentation

| Document | Purpose |
|----------|---------|
| [Copilot Instructions](.github/copilot-instructions.md) | Complete deployment guide & architecture |
| [Dependency Resolution](.github/instructions/dependency-resolution.instructions.md) | State federation patterns |
| [WORKSPACE.md](../../WORKSPACE.md) | Navigation guide for both repos |
| [terraform-azurerm-caf AGENTS.md](../../terraform-azurerm-caf/.github/AGENTS.md) | Module creation agents |
| [Rover Documentation](https://github.com/aztfmodnew/rover) | Container-based Terraform execution |

---

## ⚠️ Critical Rules

### Landing Zone Hierarchy
```
✅ CORRECT:
  L3 → reads from L0, L1, L2
  L2 → reads from L0, L1
  L1 → reads from L0
  L0 → reads nothing (root)

❌ WRONG:
  L1 → reads from L2 (higher level - NOT ALLOWED)
  L0 → reads from other levels (not self-contained)
```

### State Management
```
✅ CORRECT:
  - Level 0: No tfstates map (root state)
  - Level 1+: tfstates.launchpad with level="lower"
  - Level 2+: tfstates.foundations with level="lower" or "current"
  
❌ WRONG:
  - Using level="current" for outputs from different storage accounts
  - Circular tfstate dependencies (A depends on B, B depends on A)
  - Missing launchpad reference in level="lower"
```

### Naming Conventions
```
✅ CORRECT:
  name = "grafana-test-1"  # Let azurecaf add prefix

❌ WRONG:
  name = "rg-grafana-test-1"  # azurecaf will duplicate prefix
```

---

## 🚀 Quick Start

### Deploy Your First Landing Zone

```bash
# 1. Clone this repo
git clone https://github.com/aztfmodnew/caf-terraform-landingzones.git
cd caf-terraform-landingzones

# 2. Verify subscription (CRITICAL!)
az account show

# 3. Deploy Level 0 (launchpad)
rover -lz caf_launchpad \
  -launchpad \
  -var-folder caf_launchpad/scenario/100 \
  -level level0 \
  -a apply

# 4. Deploy Level 1 (foundations)
rover -lz caf_solution \
  -var-folder caf_solution/scenario/foundations/100-passthrough \
  -tfstate caf_foundations.tfstate \
  -level level1 \
  -a apply

# 5. Deploy Level 2 (networking)
rover -lz caf_solution \
  -var-folder caf_solution/scenario/networking/100-single-region-hub \
  -tfstate caf_networking.tfstate \
  -level level2 \
  -a apply

# Success! 🎉
```

---

## 🤔 FAQ

**Q: Can I skip Level 1 and go directly from L0 to L2?**  
A: Not recommended, but technically possible with careful configuration. L1 provides identity and governance foundations that L2 depends on.

**Q: What if I want to deploy only one level for testing?**  
A: Use unique `--environment` flag: `rover ... --environment test123`. This isolates state and prevents conflicts.

**Q: How do I redeploy a level without affecting others?**  
A: Each level has its own tfstate file. Redeploying L2 won't affect L1 or L3, as long as tfstate references are correct.

**Q: I deployed L3 but it failed. Can I rerun just L3?**  
A: Yes. Rerun the exact same rover command. Terraform will detect the state and only apply missing resources.

---

**Last Updated:** March 2026  
**Namespace:** aztfmodnew/caf-terraform-landingzones  
**Active Agents:** 5 (with specialized cross-repo coordination via Orchestrator)
