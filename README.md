# terraform-oci-fk-devops-pipeline

This repository contains a reusable **Terraform/OpenTofu module** and progressive examples for provisioning **OCI DevOps build and deploy pipelines**.

It is part of the **[FoggyKitchen.com training ecosystem](https://foggykitchen.com/courses-2/)** and is designed to compose with **`terraform-oci-fk-devops`**, which provides the surrounding shared DevOps resources such as projects, repositories, artifacts, and deploy environments.

Support expectations are documented in [SUPPORT.md](SUPPORT.md).

---

## Used By

This module is used as a building block by the higher-level [FoggyKitchen Landing Zone Orchestrator](https://github.com/foggykitchen/foggykitchen-landing-zone-orchestrator), where it is composed into Azure, OCI, and multicloud landing zone patterns.

## Purpose

The goal of this module is to model the **pipeline graph** itself:

- build pipelines
- build stages
- build triggers
- deploy pipelines
- deploy stages

It focuses on the stage orchestration patterns used in the original OCI DevOps training repository:

- build
- deliver artifact
- trigger deploy pipeline
- OKE Helm deployment
- OKE deployment
- OKE canary deployment
- blue-green deployment
- OCI Functions deployment
- invoke function validation stages
- manual approval and traffic shift stages

---

## What the module does

The module creates:

- OCI DevOps build pipelines
- OCI DevOps build pipeline stages
- OCI DevOps triggers that start build pipelines
- OCI DevOps deploy pipelines
- OCI DevOps deploy stages

The module intentionally does **not** create:

- DevOps project
- source repositories
- deploy artifacts
- deploy environments
- OKE clusters
- IAM, networking, or registries

Those inputs are expected to come from `terraform-oci-fk-devops` and companion infrastructure modules.

---

## Repository Structure

```bash
terraform-oci-fk-devops-pipeline/
├── examples/
│   ├── 01_build_pipeline/
│   ├── 02_canary_deploy_pipeline/
│   └── README.md
├── main.tf
├── inputs.tf
├── outputs.tf
├── versions.tf
├── LICENSE
└── README.md
```

---

## Example Usage

### Build pipeline with build and deliver stages

```hcl
module "fk_devops_pipeline" {
  source = "git::https://github.com/foggykitchen/terraform-oci-fk-devops-pipeline.git?ref=v0.1.0"

  project_id = var.project_id

  build_pipelines = {
    app = {
      display_name = "fk-build"
      stages = [
        {
          key              = "build"
          stage_type       = "BUILD"
          display_name     = "build"
          build_spec_file  = "build_spec.yaml"
          image            = "OL7_X86_64_STANDARD_10"
          build_sources = [
            {
              name           = "app"
              repository_id  = var.repository_id
              repository_url = var.repository_url
            }
          ]
        },
        {
          key          = "deliver"
          stage_type   = "DELIVER_ARTIFACT"
          display_name = "deliver"
          predecessor_keys = ["build"]
          deliver_artifacts = [
            {
              artifact_id   = var.deploy_artifact_id
              artifact_name = "APPLICATION_DOCKER_IMAGE"
            }
          ]
        }
      ]
    }
  }
}
```

---

## Module Inputs

| Variable | Type | Required | Description |
|--------|------|----------|-------------|
| `project_id` | `string` | yes | OCI DevOps project OCID |
| `build_pipelines` | `map(object)` | no | Build pipeline definitions including stage lists |
| `deploy_pipelines` | `map(object)` | no | Deploy pipeline definitions including stage lists |
| `triggers` | `map(object)` | no | Trigger definitions that start build pipelines managed by this module |

The module expects all referenced repositories, artifacts, and environments to already exist.

For `TRIGGER_DEPLOYMENT_PIPELINE` build stages, pass either `deploy_pipeline_id` for an externally managed deployment pipeline or `deploy_pipeline_key` when the target deployment pipeline is created by the same module call.

For OKE canary deployment pipelines, the module supports the OCI DevOps stage chain:

1. `OKE_CANARY_DEPLOYMENT`
2. optional `INVOKE_FUNCTION` validation
3. `OKE_CANARY_TRAFFIC_SHIFT`
4. `OKE_CANARY_APPROVAL`
5. `OKE_DEPLOYMENT` for production release

The canary deployment stage uses `canary_strategy` with an ingress resource and canary namespace. The traffic shift and approval stages reference upstream stages by logical stage keys, allowing the module to resolve the generated OCI DevOps stage OCIDs inside the same pipeline graph. Deploy stage dependencies are materialized across multiple resource levels so chained stages can depend on earlier generated stages without creating a Terraform graph cycle.

For `INVOKE_FUNCTION` stages, pass `function_deploy_environment_id`, `is_async`, and `is_validation_enabled`. The function environment is expected to be created outside this module, usually by `terraform-oci-fk-devops` as a deploy environment of type `FUNCTION`. When `deploy_artifact_id` is provided, OCI DevOps includes that artifact in the function invocation body during stage execution.

```hcl
{
  key                            = "validate_canary"
  stage_type                     = "INVOKE_FUNCTION"
  display_name                   = "validate-canary"
  predecessor_keys               = ["canary_deploy"]
  function_deploy_environment_id = var.function_deploy_environment_id
  is_async                       = false
  is_validation_enabled          = true
  deploy_artifact_id             = var.validation_payload_artifact_id
}
```

For `COMPUTE_INSTANCE_GROUP_ROLLING_DEPLOYMENT` stages, pass `compute_instance_group_deploy_environment_id`, `deploy_artifact_ids`, `deployment_spec_deploy_artifact_id`, and `rollout_policy`. The compute instance group environment is expected to be created outside this module, usually by `terraform-oci-fk-devops` as a deploy environment of type `COMPUTE_INSTANCE_GROUP`.

For OCI Functions deployment pipelines, use a `DEPLOY_FUNCTION` stage. The function deploy environment is expected to come from `terraform-oci-fk-devops` as a deploy environment of type `FUNCTION`, while the Docker image artifact is expected to be created by the DevOps resource module and delivered by the build pipeline.

```hcl
{
  key                             = "deploy_function"
  stage_type                      = "DEPLOY_FUNCTION"
  display_name                    = "deploy-function"
  function_deploy_environment_id  = var.function_deploy_environment_id
  docker_image_deploy_artifact_id = var.function_image_artifact_id
  max_memory_in_mbs               = 256
  function_timeout_in_seconds     = 120
  config = {
    RELEASE = "devops"
  }
}
```

---

## Module Outputs

| Output | Description |
|--------|-------------|
| `build_pipeline_ids` | Map of build pipeline OCIDs |
| `build_stage_ids` | Map of build stage OCIDs keyed by `pipeline:stage` |
| `deploy_pipeline_ids` | Map of deploy pipeline OCIDs |
| `deploy_stage_ids` | Map of deploy stage OCIDs keyed by `pipeline:stage` |
| `trigger_ids` | Map of trigger OCIDs |
| `trigger_urls` | Map of trigger URLs |

---

## Typical Integration Pattern

1. Create project, repositories, artifacts, and environments with `terraform-oci-fk-devops`
2. Create build pipelines, deploy pipelines, stages, and pipeline triggers with `terraform-oci-fk-devops-pipeline`
3. Compose the two modules in a higher-level lesson, blueprint, or landing zone

This keeps the shared DevOps control plane separated from the delivery graph definition.

---

## Examples

Runnable examples are available in [examples](examples/README.md).

They show:

- a build pipeline pattern
- a canary deploy pipeline pattern

---

## Contributing

This project is open source. Contributions are welcome through pull requests.

---

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [LICENSE](LICENSE) for details.

---

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
