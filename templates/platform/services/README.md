{% set readme_landingzones_folder = landingzones_folder | default(base_folder ~ '/landingzones') %}
{% set readme_caf_landingzone_branch = topology.caf_landingzone_branch | default(caf_landingzone_branch | default('main')) %}
{% set readme_topology_file = topology_file | default(public_templates_folder ~ '/platform/caf_platform_prod_nonprod.yaml') %}
{% set readme_runner_numbers = RUNNER_NUMBERS | default(1) %}
{% set readme_agent_token = AGENT_TOKEN | default('bootstrap-placeholder-token') %}
{% set readme_gitops_agent = gitops_agent | default('github') %}
{% set readme_rover_agent_image = ROVER_AGENT_DOCKER_IMAGE | default(topology.gitops_default_rover_image | default(topology.default_rover_image | default(''))) %}
{% set readme_subscription_deployment_mode = subscription_deployment_mode | default(topology.subscription_deployment_mode | default('single_reuse')) %}
{% set readme_sub_management = sub_management | default('') %}
{% set readme_sub_connectivity = sub_connectivity | default('') %}
{% set readme_sub_identity = sub_identity | default('') %}
{% set readme_sub_security = sub_security | default('') %}
{% set readme_gitops_pipelines = gitops_pipelines | default(readme_gitops_agent) %}
{% set readme_bootstrap_sp_object_id = bootstrap_sp_object_id | default(object_id | default('')) %}
# Cloud Adoption Framework landing zones for Terraform - Ignite the Azure Platform and landing zones


:rocket: START HERE: [Follow the onboarding guide from](https://aztfmod.github.io/documentation/docs/azure-landing-zones/landingzones/platform/org-setup)


For further executions or command, you can refer to the following sections

## Commands

### Rover ignite the platform

Rover ignite will  process the YAML files and start building the configuration structure of the TFVARS. 

Please note that during the creation of the platform landingones you will have to run rover ignite multiple times as some deployments are required to be completed before you can perform the next steps. 

The best course of actions is to follow the readme files generated within each landing zones, as rover ignite creates the tfvars and also the documentation.

Once you are ready to ingite, just run:

```bash
rover login -t {{ azure_landing_zones.identity.tenant_name | default(tenant_name)}} -s {{subscription_id.stdout}}

ansible-playbook $(readlink -f ./landingzones/templates/ansible/ansible.yaml) \
  --extra-vars "@$(readlink -f ./platform/definition/ignite.yaml)" \
  -e base_folder=$(pwd)

```

### Next step

Once the rover ignite command has been executed, go to your configuration folder when the platform launchpad configuration has been created.

Get started with the [launchpad]({{destination_path}}/{{resources.launchpad.relative_destination_folder}})



## References

Whenever needed, or under a profesional supervision you can use the following commands

### Clone the landingzone project (Terraform base code)

```bash
git clone https://github.com/Azure/caf-terraform-landingzones.git {{ readme_landingzones_folder }}
cd {{ readme_landingzones_folder }} && git fetch origin
git checkout {{ readme_caf_landingzone_branch }}

```

### Regenerate the definition folder

For your reference, if you need to re-generate the YAML definition files later, you can run the following command: 

```bash

ansible-playbook $(readlink -f ./landingzones/templates/ansible/walk-through-ci.yaml) \
  --extra-vars "@$(readlink -f ./platform/definition/ignite.yaml)" \
  -e base_folder=$(pwd) \
  -e topology_file={{ readme_topology_file }} \
  -e GITHUB_SERVER_URL={{lookup('env', 'GITHUB_SERVER_URL')}} \
  -e GITHUB_REPOSITORY={{lookup('env', 'GITHUB_REPOSITORY')}} \
  -e GITOPS_SERVER_URL={{lookup('env', 'GITHUB_SERVER_URL')}}/{{lookup('env', 'GITHUB_REPOSITORY')}} \
  -e RUNNER_NUMBERS={{ readme_runner_numbers }} \
  -e AGENT_TOKEN={{ readme_agent_token }} \
  -e gitops_agent={{ readme_gitops_agent }} \
  -e ROVER_AGENT_DOCKER_IMAGE={{ readme_rover_agent_image }} \
  -e subscription_deployment_mode={{ readme_subscription_deployment_mode }} \
  -e sub_management={{ readme_sub_management }} \
  -e sub_connectivity={{ readme_sub_connectivity }} \
  -e sub_identity={{ readme_sub_identity }} \
  -e sub_security={{ readme_sub_security }} \
  -e gitops_pipelines={{ readme_gitops_pipelines }} \
  -e TF_VAR_environment={{caf_environment}} \
  -e bootstrap_sp_object_id={{ readme_bootstrap_sp_object_id }} \
  -e template_folder="$(pwd)/platform/definition"

```
