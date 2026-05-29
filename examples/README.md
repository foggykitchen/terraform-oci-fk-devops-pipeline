# Examples

This directory contains runnable examples for **`terraform-oci-fk-devops-pipeline`**.

## Example Overview

| Example | Description |
|--------|-------------|
| [01_build_pipeline](01_build_pipeline) | Models a build pipeline with build and deliver stages |
| [02_canary_deploy_pipeline](02_canary_deploy_pipeline) | Models a canary deploy pipeline with traffic shift and approval stages |

## How To Use

Each example is self-contained:

```bash
tofu init
tofu plan
```

Provide your own OCI values through `terraform.tfvars` or environment variables.

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [../LICENSE](../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
