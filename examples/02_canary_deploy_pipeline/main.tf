module "fk_devops_pipeline" {
  source = "../.."

  project_id = var.project_id

  deploy_pipelines = {
    app = {
      display_name = "fk-canary-deploy"
      stages = [
        {
          key                                     = "canary_deploy"
          stage_type                              = "OKE_CANARY_DEPLOYMENT"
          display_name                            = "canary deploy"
          deploy_environment_id                   = var.deploy_environment_id
          kubernetes_manifest_deploy_artifact_ids = [var.manifest_artifact_id]
          canary_strategy = {
            ingress_name  = "fk-app-ing"
            namespace     = "foggykitchen"
            strategy_type = "NGINX_CANARY_STRATEGY"
          }
        },
        {
          key                         = "traffic_shift"
          stage_type                  = "OKE_CANARY_TRAFFIC_SHIFT"
          display_name                = "traffic shift"
          predecessor_keys            = ["canary_deploy"]
          oke_canary_deploy_stage_key = "canary_deploy"
          rollout_policy = {
            batch_count            = 1
            batch_delay_in_seconds = 60
            batch_percentage       = 0
            ramp_limit_percent     = 10
          }
        },
        {
          key                                = "approval"
          stage_type                         = "OKE_CANARY_APPROVAL"
          display_name                       = "approval"
          predecessor_keys                   = ["traffic_shift"]
          oke_canary_traffic_shift_stage_key = "traffic_shift"
          approval_policy = {
            approval_policy_type         = "COUNT_BASED_APPROVAL"
            number_of_approvals_required = 1
          }
        },
        {
          key                                     = "production_release"
          stage_type                              = "OKE_DEPLOYMENT"
          display_name                            = "production release"
          predecessor_keys                        = ["approval"]
          deploy_environment_id                   = var.deploy_environment_id
          namespace                               = "foggykitchen"
          kubernetes_manifest_deploy_artifact_ids = [var.manifest_artifact_id]
          rollback_policy = {
            policy_type = "AUTOMATED_STAGE_ROLLBACK_POLICY"
          }
        }
      ]
    }
  }
}
