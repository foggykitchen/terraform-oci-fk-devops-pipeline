# Example 02

This example models a canary deployment pipeline:

- canary deploy
- traffic shift
- approval
- production release

It is intended to consume an existing DevOps project, OKE deploy environment, and manifest artifact.

The canary deployment stage uses an OKE canary strategy based on an ingress resource and a canary namespace. The traffic shift and approval stages reference earlier stages by logical keys:

- `oke_canary_deploy_stage_key` points to the canary deployment stage
- `oke_canary_traffic_shift_stage_key` points to the traffic shift stage

This lets the module resolve stage OCIDs after Terraform creates the pipeline graph.

## Expected OKE Prerequisites

Before applying this example, the target OKE cluster should already have:

- a production namespace for the stable release
- a canary namespace for the canary release
- an ingress resource with the name used by `canary_strategy.ingress_name`
- an ingress controller compatible with the selected canary strategy, such as ingress-nginx for `NGINX_CANARY_STRATEGY`

## Usage

```bash
tofu init
tofu plan
```

## License

Licensed under the **Universal Permissive License (UPL), Version 1.0**.
See [../../LICENSE](../../LICENSE) for details.

© 2026 [FoggyKitchen.com](https://foggykitchen.com) - Cloud. Code. Clarity.
