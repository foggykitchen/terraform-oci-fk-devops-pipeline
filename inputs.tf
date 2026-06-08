variable "project_id" {
  description = "OCI DevOps project OCID that owns the pipelines."
  type        = string
}

variable "build_pipelines" {
  description = "Map of OCI DevOps build pipelines keyed by logical name."
  type = map(object({
    display_name = string
    description  = optional(string)
    parameters = optional(list(object({
      name          = string
      default_value = string
      description   = optional(string)
    })), [])
    stages = list(object({
      key                                = string
      stage_type                         = string
      display_name                       = string
      description                        = optional(string)
      predecessor_keys                   = optional(list(string), [])
      build_spec_file                    = optional(string)
      image                              = optional(string)
      stage_execution_timeout_in_seconds = optional(number)
      wait_duration                      = optional(string)
      wait_type                          = optional(string)
      build_sources = optional(list(object({
        connection_type = optional(string, "DEVOPS_CODE_REPOSITORY")
        connection_id   = optional(string)
        branch          = optional(string, "main")
        name            = string
        repository_id   = optional(string)
        repository_url  = string
      })), [])
      deliver_artifacts = optional(list(object({
        artifact_id   = string
        artifact_name = string
      })), [])
      deploy_pipeline_id             = optional(string)
      deploy_pipeline_key            = optional(string)
      is_pass_all_parameters_enabled = optional(bool, false)
    }))
  }))
  default = {}
}

variable "deploy_pipelines" {
  description = "Map of OCI DevOps deploy pipelines keyed by logical name."
  type = map(object({
    display_name = string
    description  = optional(string)
    parameters = optional(list(object({
      name          = string
      default_value = string
      description   = optional(string)
    })), [])
    stages = list(object({
      key                                     = string
      stage_type                              = string
      display_name                            = string
      description                             = optional(string)
      predecessor_keys                        = optional(list(string), [])
      deploy_environment_id                   = optional(string)
      namespace                               = optional(string)
      kubernetes_manifest_deploy_artifact_ids = optional(list(string), [])
      helm_chart_deploy_artifact_id           = optional(string)
      release_name                            = optional(string)
      values_artifact_ids                     = optional(list(string), [])
      are_hooks_enabled                       = optional(bool)
      should_reuse_values                     = optional(bool)
      should_not_wait                         = optional(bool)
      max_history                             = optional(number)
      timeout_in_seconds                      = optional(number)
      purpose                                 = optional(string)
      deploy_artifact_id                      = optional(string)
      function_deploy_environment_id          = optional(string)
      docker_image_deploy_artifact_id         = optional(string)
      config                                  = optional(map(string))
      max_memory_in_mbs                       = optional(number)
      function_timeout_in_seconds             = optional(number)
      is_async                                = optional(bool)
      is_validation_enabled                   = optional(bool)
      canary_strategy = optional(object({
        ingress_name  = string
        namespace     = string
        strategy_type = string
      }))
      rollout_policy = optional(object({
        batch_count            = number
        batch_delay_in_seconds = number
        batch_percentage       = number
        ramp_limit_percent     = number
      }))
      approval_policy = optional(object({
        approval_policy_type         = string
        number_of_approvals_required = number
      }))
      rollback_policy = optional(object({
        policy_type = string
      }))
      blue_green_strategy = optional(object({
        ingress_name  = string
        namespace_a   = string
        namespace_b   = string
        strategy_type = string
      }))
      oke_canary_deploy_stage_key        = optional(string)
      oke_canary_traffic_shift_stage_key = optional(string)
      oke_blue_green_deploy_stage_key    = optional(string)
    }))
  }))
  default = {}
}

variable "triggers" {
  description = "Map of OCI DevOps triggers keyed by logical name."
  type = map(object({
    display_name       = string
    description        = optional(string)
    build_pipeline_key = string
    trigger_source     = optional(string, "DEVOPS_CODE_REPOSITORY")
    events             = optional(list(string), ["PUSH"])
    connection_id      = optional(string)
    repository_id      = optional(string)
    repository_name    = optional(string)
    head_ref           = optional(string)
    base_ref           = optional(string)
  }))
  default = {}
}

variable "defined_tags" {
  description = "Defined tags applied to supported resources."
  type        = map(string)
  default     = {}
}

variable "freeform_tags" {
  description = "Freeform tags applied to supported resources."
  type        = map(string)
  default     = {}
}
