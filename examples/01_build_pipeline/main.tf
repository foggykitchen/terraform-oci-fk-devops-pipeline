module "fk_devops_pipeline" {
  source = "../.."

  project_id = var.project_id

  build_pipelines = {
    app = {
      display_name = "fk-build"
      stages = [
        {
          key             = "build"
          stage_type      = "BUILD"
          display_name    = "build"
          build_spec_file = "build_spec.yaml"
          image           = "OL7_X86_64_STANDARD_10"
          build_sources = [
            {
              name           = "app"
              repository_id  = var.repository_id
              repository_url = var.repository_url
            }
          ]
        },
        {
          key              = "deliver"
          stage_type       = "DELIVER_ARTIFACT"
          display_name     = "deliver"
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
