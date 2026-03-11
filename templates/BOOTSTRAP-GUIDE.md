# 🚀 Rover Ignite Bootstrap Guide

**Automatically generate a complete Azure CAF landing zone configuration (L0-L3) in 15 minutes using Ansible + Jinja2 templating.**

---

## 📌 What is Rover Ignite?

Rover Ignite is a **configuration generation system** that transforms a simple topology definition (`ignite.yaml`) into 50+ production-ready Terraform configuration files (`*.tfvars`).

Instead of manually writing:
```
level0/launchpad.tfvars
level1/platform_subscriptions.tfvars
level1/identity.tfvars
level1/management.tfvars
level1/alz.tfvars
level2/connectivity_virtual_wans_prod.tfvars
level2/connectivity_virtual_wans_nonprod.tfvars
level2/virtual_hubs_prod.tfvars
level2/virtual_hubs_nonprod.tfvars
... (40+ more files)
```

You run **one playbook**, answer 10 prompts, and get all 50+ files generated, tested, and ready to deploy.

---

## ✅ When to Use Rover Ignite

| Scenario | Use Ignite? | Alternative |
|----------|------------|-------------|
| **First-time setup** | ✅ YES | Start with scenario examples |
| **Multi-subscription (5+)** | ✅ YES | Manual coordination error-prone |
| **Production deployment** | ✅ YES | Ensures consistency |
| **Learning CAF patterns** | ❌ NO | Use scenario examples first |
| **Single subscription dev/test** | ❌ Maybe | Scenarios might be simpler |
| **Firewall rule generation** | ✅ YES | 1000+ rules auto-generated |
| **Updating ignite.yaml** | ✅ YES | Re-run → regenerate all config |

---

## 🎯 Quick Start (15 minutes)

### Prerequisites
```bash
# 1. Install Ansible
pip install ansible

# 2. Clone repository
git clone https://github.com/aztfmodnew/caf-terraform-landingzones.git
cd caf-terraform-landingzones

# 3. Login to Azure
az account clear
az login  # Interactive login, or
az login --service-principal -u $CLIENT_ID -p $CLIENT_SECRET -t $TENANT_ID

# 4. Verify subscription (CRITICAL!)
az account show --query "{subscriptionId:id, name:name, state:state}" -o table
# ⚠️ STOP HERE if wrong subscription!
```

### Run Bootstrap

```bash
# Interactive mode (answers prompts)
ansible-playbook templates/platform/walk-through-bootstrap.yaml \
  -e cloud_env=public \
  -v

# Non-interactive mode (uses defaults from ignite.yaml)
ansible-playbook templates/platform/caf_platform_prod_nonprod.yaml \
  -e platform_configuration_folder=./my_config \
  -e platform_definition_folder=./my_config/topology \
  -e deployment_mode=platform \
  -v
```

### What You'll Be Asked

**Prompts (in order):**
```
1. Customer name (no spaces)               → "contoso"
2. CAF Environment                         → "prod"
3. Prefix for resources                    → "caf"
4. Management group prefix (2-10 chars)    → "es"
5. Management group name                   → "Contoso"
6. Email for notifications                 → "ops@contoso.com"
7. Azure regions (lowercase, short)        → "region1: westeurope, region2: eastus"
8. Default CAF region key                  → "region1"
9. GitOps agent (github or tfcloud)        → "github"
10. Subscriptions (management, connectivity, identity, security)
```

### Output
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
│   ├── connectivity_virtual_wans_nonprod.tfvars
│   ├── virtual_hubs_prod.tfvars
│   └── ... (25+ more files)
└── .github/workflows/
    ├── deploy-level0.yaml
    ├── deploy-level1.yaml
    └── deploy-level2.yaml
```

All files **terraform fmt'ed**, **ready to apply**, with state federation configured automatically ✅

---

## 🔧 Advanced: Multi-Subscription Deployment

If you have **separate subscriptions** for management, connectivity, identity, and security:

```bash
rover -bootstrap \
  -aad-app-name contoso-platform-landing-zones \
  -gitops-service github \
  -gitops-number-runners 4 \
  -bootstrap-script './templates/platform/deploy_platform.sh' \
  -playbook './templates/platform/caf_platform_prod_nonprod.yaml' \
  -subscription-deployment-mode multi_subscriptions \
  -sub-management <MANAGEMENT_SUBSCRIPTION_GUID> \
  -sub-connectivity <CONNECTIVITY_SUBSCRIPTION_GUID> \
  -sub-identity <IDENTITY_SUBSCRIPTION_GUID> \
  -sub-security <SECURITY_SUBSCRIPTION_GUID>
```

**What this does:**
- Creates service principals for cross-subscription access
- Configures RBAC automatically
- Generates all tfvars with correct subscription references
- Sets up CI/CD GitHub Actions for multi-sub deployment
- Whitelists your IP in all firewalls

---

## 📋 Understanding ignite.yaml

The **root configuration file** that controls everything.

### Structure

```yaml
bootstrap:
  # Tenant and subscription definitions
  caf_environment: prod
  azure_landing_zones:
    identity:
      tenant_name: "contoso.onmicrosoft.com"
      subscription_id: "xxxxx"
  
  # Deployment topology (which services in which regions)
  deployments:
    platform:
      root:
        region1:
          launchpad: launchpad.yaml    # Loads services/launchpad.yaml
          identity: identity.yaml       # Loads services/identity.yaml
          platform_subscriptions: platform_subscriptions.yaml
      
      alz:  # Azure Landing Zones (optional)
        region1:
          es: alz.yaml  # Management groups + policies
      
      # Scale-out domains: prod/nonprod environments
      scale_out_domains:
        region1:
          identity_level2:
            prod: identity_level2.yaml
            nonprod: identity_level2_nonprod.yaml
          
          connectivity_virtual_wans:
            prod: connectivity_virtual_wans.yaml
          
          virtual_hubs:
            prod: virtual_hubs.yaml
            nonprod: virtual_hubs_nonprod.yaml
```

### Key Sections

| Section | Purpose | Example |
|---------|---------|---------|
| **bootstrap.caf_environment** | Environment identifier | `prod`, `dev`, `test` |
| **azure_landing_zones.identity.tenant_name** | Azure AD tenant | `contoso.onmicrosoft.com` |
| **deployments.platform.root** | L0-L1 bootstrap (must complete first) | launchpad, identity, management |
| **deployments.platform.alz** | Azure Landing Zones (management groups, policies) | Optional, advanced |
| **deployments.platform.scale_out_domains** | L2-L3 scale-out (can have prod/nonprod variants) | connectivity, hubs, virtual networks |

### ALZ Library & Feature Flags (per landing zone)

You can now define ALZ policy composition behavior directly under `bootstrap.management_groups.<region>.<mg_key>.alz_library`:

```yaml
bootstrap:
  management_groups:
    region1:
      es:
        version_to_deploy: "v2.1.0"
        alz_library:
          source: "embedded"   # embedded | external
          version: "v2.1.0"
          enable_amba: false
          enable_slz: false
          # amba_version: "main"   # Optional: pin to a specific AMBA git tag (e.g. "2024-03-01")
          # slz_version: "main"    # Optional: pin to a specific SLZ git tag or branch
```

#### Current implementation status

- `source: embedded` ✅ supported (default)
- `source: external` ⚠️ reserved for next phase (currently fails fast with a clear message)
- `enable_amba` ✅ implemented — clones `Azure/azure-monitor-baseline-alerts` from GitHub and merges `patterns/alz/lib/` into the ALZ lib folder
- `enable_slz` ✅ implemented — clones `Azure/sovereign-landing-zone` from GitHub and merges sovereignty policy files into the ALZ lib folder
- `amba_version` ✅ optional — defaults to `"main"`, can be set to any git tag or branch
- `slz_version` ✅ optional — defaults to `"main"`, can be set to any git tag or branch

This lets you standardize a common model across all landing zones while enabling progressive rollout by environment or business domain.

---

## 🔄 Ansible Playbook Flow

Here's what happens when you run the playbook:

### Phase 1: Bootstrap Collection
```yaml
walk-through-bootstrap.yaml
  ↓ Ask questions (customer_name, email, regions, subscriptions)
  ↓ Store in variables
```

### Phase 2: Azure Discovery
```yaml
walk-through.yaml
  ↓ Call: az account show → get tenant_id, object_id
  ↓ Call: curl https://ifconfig.me → get IP (for firewall whitelist)
  ↓ Store in bootstrap context
```

### Phase 3: Orchestration (Main)
```yaml
ansible.yaml (orchestrator)
  ├─ include_vars: ignite.yaml → bootstrap topology definition
  ├─ include_vars: services/*.yaml → resource config schemas
  ├─ set_fact: global variables (regions, subscriptions, etc.)
  ├─ include_tasks: load_regions.yaml → iterate regions
  ├─ include_tasks: load_deployments.yaml → iterate services
  ├─ include_tasks: get_tfstate_content.yaml → L0 state → L1+ refs
  ├─ include_tasks: load_firewall_rules.yaml (if platform mode)
  └─ include_tasks: render_template.yaml → Jinja2 rendering
```

### Phase 4: Template Rendering
```yaml
render_template.yaml
  ├─ Template: resources/keyvault.j2
  │  ├─ Variables: {{ bootstrap.subscriptions }}, {{ platform_subscriptions }}
  │  ├─ Conditionals: {% if private_endpoints is defined %}
  │  └─ Output: level1/keyvault.tfvars
  │
  ├─ Template: resources/virtual_network.j2
  │  ├─ Variables: {{ vnets[vnet_key] }}, {{ subnets }}
  │  └─ Output: level2/networking.tfvars
  │
  └─ ... (50+ templates total)
```

### Phase 5: Cleanup
```bash
terraform fmt --recursive configuration/
rm -f configuration/**/*_tmp.tfvars   # Remove temp files
```

---

## 🎨 Jinja2 Template Examples

All templates are in `templates/resources/*.j2`

### Example: keyvault.j2
```jinja2
{% for keyvault_key, keyvault in module_keyvaults.items() %}
"{{ keyvault_key }}" = {
  name                = "{{ keyvault.name }}"
  resource_group_key  = "{{ keyvault.resource_group_key }}"
  sku_name            = "{{ keyvault.sku_name | default('standard') }}"
  
  # Conditional: only if private endpoints defined
  {% if keyvault.private_endpoints is defined %}
  private_endpoints = {
    {% for pe_key, pe_config in keyvault.private_endpoints.items() %}
    "{{ pe_key }}" = {
      name                = "{{ pe_config.name }}"
      subnet_id           = "{{ subnets[pe_config.subnet_key].id }}"
      subresource_names   = {{ pe_config.subresource_names }}
    }
    {% endfor %}
  }
  {% endif %}
}
{% endfor %}
```

### Template Variables Available

```yaml
bootstrap:            # From walk-through prompts
  customer_name: "contoso"
  caf_environment: "prod"
  subscriptions: {mgmt: ID, conn: ID, id: ID, sec: ID}

platform_subscriptions:  # Extracted from ignite.yaml
  management: {name, subscription_id, owner}
  connectivity: {name, subscription_id, owner}
  identity: {name, subscription_id, owner}

regions:              # Parsed from ignite.yaml
  region1: "westeurope"
  region2: "eastus"

resources:            # From previous level tfstate (state federation)
  keyvaults:
    launchpad_kv:
      id: "/subscriptions/.../providers/Microsoft.KeyVault/vaults/caf-kv"
      name: "caf-kv"
  
  storage_accounts:
    tfstate_sa:
      id: "/subscriptions/.../providers/Microsoft.Storage/storageAccounts/caftfstate"
      primary_blob_endpoint: "https://caftfstate.blob.core.windows.net"
```

---

## 🔐 State Federation (Automatic)

The system **automatically configures cross-level references**:

### How It Works

1. **Deploy L0** → Launchpad creates:
   - Storage account (for tfstate)
   - Key Vault (for secrets)
   - Managed identities
   - Service principals

2. **Playbook reads L0 tfstate** → Extracts:
   ```hcl
   # From L0 outputs
   launchpad_keyvault_id = "/subscriptions/.../keyvault/caf-kv"
   tfstate_storage_account_name = "caftfstate"
   launchpad_managed_identity_id = "/subscriptions/.../identity/caf-identity"
   ```

3. **L1-L3 tfvars generated with correct references**:
   ```hcl
   # In level1/identity.tfvars (auto-generated)
   keyvault_id = "/subscriptions/.../keyvault/caf-kv"  # ← From L0
   
   # In level2/networking.tfvars (auto-generated)
   remote_objects = {
     keyvaults = {...}  # ← References from L0
     managed_identities = {...}  # ← References from L0
   }
   ```

4. **Deploy L1-L3** → Terraform reads remote state automatically ✅

---

## 🚨 Common Issues & Solutions

### Issue 1: "Connection refused" → Ansible can't reach Azure

**Solution:**
```bash
az account clear
az login --tenant <TENANT_ID>  # Explicit tenant
az account show  # Verify
```

### Issue 2: "Permission denied" → No access to subscription

**Solution:**
```bash
# Check role assignment
az role assignment list --assignee $(az ad signed-in-user show --query id -o tsv)

# If no roles, ask admin to assign:
az role assignment create \
  --role Owner \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --scope /subscriptions/<SUBSCRIPTION_ID>
```

### Issue 3: "ignite.yaml not found"

**Solution:**
```bash
# Check directory structure
ls -la templates/platform/ignite.yaml

# Or specify custom location
ansible-playbook templates/platform/walk-through-bootstrap.yaml \
  -e platform_definition_folder=/path/to/my/ignite
```

### Issue 4: Generated tfvars have syntax errors

**Solution:**
```bash
# Check Jinja2 rendering issues
ls -la configuration/**/*_tmp.tfvars  # Temp files (if cleanup failed)

# Re-run with verbose
ansible-playbook ... -vvv  # Ansible debug output

# Validate generated files
terraform -chdir=configuration/level0 validate
```

### Issue 5: State federation broken (L1 can't find L0 outputs)

**Solution:**
```bash
# Verify L0 deployed and state exists
az storage blob list \
  --container-name tfstate \
  --account-name <your-tfstate-storage> \
  --query "[].name"

# If missing, deploy L0 first
rover -lz caf_launchpad -level level0 -a apply
```

---

## 📊 Comparison: Ignite vs. Manual Configuration

| Aspect | Ignite | Manual Scenarios |
|--------|--------|------------------|
| **Time to deploy (L0-L3)** | 15 min | 2-3 hours |
| **Files to write** | 0 (all auto-generated) | 50+ file edits |
| **Subscriptions** | Multi-sub orchestrated | Single or manual coordination |
| **Firewall rules** | 1000+ auto-generated | Hand-coded rule by rule |
| **State federation** | Automatic | Manual subscription ID tracking |
| **Learning curve** | Moderate | Low (start simple) |
| **Customization** | Edit ignite.yaml | Edit each tfvars |
| **Prod-ready** | ✅ Yes | Requires testing |
| **Reproducibility** | ✅ Idempotent | Manual consistency |

---

## 🔁 Updating Configuration (Idempotent)

One of the best features: **update ignite.yaml → regenerate everything**.

### Scenario: Add a new region

```yaml
# Edit: templates/platform/ignite.yaml
bootstrap:
  deployments:
    platform:
      root:
        region1:  # Existing
          launchpad: launchpad.yaml
        region2:  # NEW!
          launchpad: launchpad.yaml
          identity: identity.yaml
```

Then:
```bash
ansible-playbook templates/platform/caf_platform_prod_nonprod.yaml \
  -e platform_definition_folder=./topology
```

Result: **All 50+ tfvars regenerated with new region included** ✅

---

## 🎓 Next Steps

### Step 1: Bootstrap L0
```bash
rover -lz caf_launchpad \
  -launchpad \
  -var-folder configuration/level0 \
  -level level0 -a apply
```

### Step 2: Bootstrap L1
```bash
rover -lz caf_solution \
  -var-folder configuration/level1 \
  -tfstate caf_foundations.tfstate \
  -level level1 -a apply
```

### Step 3: Deploy L2
```bash
rover -lz caf_solution \
  -var-folder configuration/level2 \
  -tfstate caf_networking.tfstate \
  -level level2 -a apply
```

### Step 4: Monitor
Outputs are stored in your launchpad Key Vault:
```bash
az keyvault secret list \
  --vault-name <your-keyvault> \
  --query "[].name"
```

---

## 📚 Related Files & Directories

| Path | Purpose |
|------|---------|
| `templates/platform/ignite.yaml` | Master configuration file (customize this) |
| `templates/ansible/ansible.yaml` | Main orchestrator playbook |
| `templates/ansible/walk-through-bootstrap.yaml` | Interactive setup entry point |
| `templates/resources/` | 50+ Jinja2 resource templates (*.j2) |
| `templates/platform/services/` | Service definitions (launchpad, identity, etc.) |
| `templates/asvm/ignite.yaml` | ASVM/Orion config (if using data platform) |
| `.github/workflows/` | Auto-generated CI/CD pipelines |

---

## 🤔 FAQ

**Q: Can I use Ignite for a single subscription?**  
A: Yes, but you'd typically configure everything in one subscription, which limits isolation benefits.

**Q: Can I customize resource names beyond ignite.yaml?**  
A: Yes. Edit the Jinja2 templates in `templates/resources/` to change naming logic.

**Q: What if I mess up ignite.yaml?**  
A: Git version control it. Or re-clone and re-run. The playbook is idempotent.

**Q: Can I run Ignite without Ansible?**  
A: Technically yes (all it does is generate tfvars), but Ansible + Jinja2 is the official method.

**Q: How do I skip certain services?**  
A: Comment out in `ignite.yaml` under the relevant level.

**Q: ASVM — what is it?**  
A: Azure Subscription Vending Machine (Orion): specialized deployment for data/AI platforms. See `templates/asvm/ignite.yaml`.

---

## 💡 Pro Tips

1. **Always git commit ignite.yaml** → Track changes, easy to revert
2. **Use unique customer names** → Keeps naming consistent across regions
3. **Test in dev first** → Change `caf_environment: prod` → `dev`, then replay
4. **Keep firewall rules centralized** → Edit `firewall_rules.yaml` once, regenerate 1000+ rules
5. **Monitor regeneration** → Use `terraform plan` before `apply` (always!)

---

**Last Updated:** March 2026  
**Maintained by:** aztfmodnew Community  
**Quick Link:** [Rover Ignite Orchestrator Agent](../.github/AGENTS.md#rover-ignite-orchestrator)
