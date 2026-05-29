locals {
  build_stage_items = flatten([
    for pipeline_key, pipeline in var.build_pipelines : [
      for stage in pipeline.stages : merge(stage, {
        pipeline_key = pipeline_key
        id_key       = "${pipeline_key}:${stage.key}"
      })
    ]
  ])

  build_stage_map = {
    for stage in local.build_stage_items : stage.id_key => stage
  }

  build_root_stage_map = {
    for key, stage in local.build_stage_map : key => stage
    if length(stage.predecessor_keys) == 0
  }

  build_dependent_stage_map = {
    for key, stage in local.build_stage_map : key => stage
    if length(stage.predecessor_keys) > 0
  }

  deploy_stage_items = flatten([
    for pipeline_key, pipeline in var.deploy_pipelines : [
      for stage in pipeline.stages : merge(stage, {
        pipeline_key = pipeline_key
        id_key       = "${pipeline_key}:${stage.key}"
      })
    ]
  ])

  deploy_stage_map = {
    for stage in local.deploy_stage_items : stage.id_key => stage
  }

  deploy_root_stage_map = {
    for key, stage in local.deploy_stage_map : key => stage
    if length(stage.predecessor_keys) == 0
  }

  deploy_dependent_stage_map = {
    for key, stage in local.deploy_stage_map : key => stage
    if length(stage.predecessor_keys) > 0
  }
}

resource "oci_devops_build_pipeline" "this" {
  for_each = var.build_pipelines

  project_id    = var.project_id
  display_name  = each.value.display_name
  description   = coalesce(each.value.description, each.value.display_name)
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  dynamic "build_pipeline_parameters" {
    for_each = length(each.value.parameters) == 0 ? [] : [each.value.parameters]
    content {
      dynamic "items" {
        for_each = build_pipeline_parameters.value
        content {
          name          = items.value.name
          default_value = items.value.default_value
          description   = try(items.value.description, null)
        }
      }
    }
  }
}

resource "oci_devops_build_pipeline_stage" "root" {
  for_each = local.build_root_stage_map

  build_pipeline_id                  = oci_devops_build_pipeline.this[each.value.pipeline_key].id
  build_pipeline_stage_type          = each.value.stage_type
  display_name                       = each.value.display_name
  description                        = coalesce(each.value.description, each.value.display_name)
  build_spec_file                    = each.value.stage_type == "BUILD" ? try(each.value.build_spec_file, null) : null
  image                              = each.value.stage_type == "BUILD" ? try(each.value.image, null) : null
  stage_execution_timeout_in_seconds = each.value.stage_type == "BUILD" ? try(each.value.stage_execution_timeout_in_seconds, null) : null
  deploy_pipeline_id                 = each.value.stage_type == "TRIGGER_DEPLOYMENT_PIPELINE" ? try(each.value.deploy_pipeline_id, null) : null
  is_pass_all_parameters_enabled     = each.value.stage_type == "TRIGGER_DEPLOYMENT_PIPELINE" ? try(each.value.is_pass_all_parameters_enabled, false) : null

  build_pipeline_stage_predecessor_collection {
    items {
      id = oci_devops_build_pipeline.this[each.value.pipeline_key].id
    }
  }

  dynamic "build_source_collection" {
    for_each = each.value.stage_type == "BUILD" && length(try(each.value.build_sources, [])) > 0 ? [each.value.build_sources] : []
    content {
      dynamic "items" {
        for_each = build_source_collection.value
        content {
          connection_type = items.value.connection_type
          branch          = items.value.branch
          name            = items.value.name
          repository_id   = items.value.repository_id
          repository_url  = items.value.repository_url
        }
      }
    }
  }

  dynamic "deliver_artifact_collection" {
    for_each = each.value.stage_type == "DELIVER_ARTIFACT" && length(try(each.value.deliver_artifacts, [])) > 0 ? [each.value.deliver_artifacts] : []
    content {
      dynamic "items" {
        for_each = deliver_artifact_collection.value
        content {
          artifact_id   = items.value.artifact_id
          artifact_name = items.value.artifact_name
        }
      }
    }
  }

  dynamic "wait_criteria" {
    for_each = each.value.stage_type == "BUILD" && try(each.value.wait_duration, null) != null && try(each.value.wait_type, null) != null ? [1] : []
    content {
      wait_duration = each.value.wait_duration
      wait_type     = each.value.wait_type
    }
  }
}

resource "oci_devops_build_pipeline_stage" "dependent" {
  for_each = local.build_dependent_stage_map

  build_pipeline_id                  = oci_devops_build_pipeline.this[each.value.pipeline_key].id
  build_pipeline_stage_type          = each.value.stage_type
  display_name                       = each.value.display_name
  description                        = coalesce(each.value.description, each.value.display_name)
  build_spec_file                    = each.value.stage_type == "BUILD" ? try(each.value.build_spec_file, null) : null
  image                              = each.value.stage_type == "BUILD" ? try(each.value.image, null) : null
  stage_execution_timeout_in_seconds = each.value.stage_type == "BUILD" ? try(each.value.stage_execution_timeout_in_seconds, null) : null
  deploy_pipeline_id                 = each.value.stage_type == "TRIGGER_DEPLOYMENT_PIPELINE" ? try(each.value.deploy_pipeline_id, null) : null
  is_pass_all_parameters_enabled     = each.value.stage_type == "TRIGGER_DEPLOYMENT_PIPELINE" ? try(each.value.is_pass_all_parameters_enabled, false) : null

  build_pipeline_stage_predecessor_collection {
    dynamic "items" {
      for_each = each.value.predecessor_keys
      content {
        id = contains(keys(local.build_root_stage_map), "${each.value.pipeline_key}:${items.value}") ? oci_devops_build_pipeline_stage.root["${each.value.pipeline_key}:${items.value}"].id : oci_devops_build_pipeline_stage.dependent["${each.value.pipeline_key}:${items.value}"].id
      }
    }
  }

  dynamic "build_source_collection" {
    for_each = each.value.stage_type == "BUILD" && length(try(each.value.build_sources, [])) > 0 ? [each.value.build_sources] : []
    content {
      dynamic "items" {
        for_each = build_source_collection.value
        content {
          connection_type = items.value.connection_type
          branch          = items.value.branch
          name            = items.value.name
          repository_id   = items.value.repository_id
          repository_url  = items.value.repository_url
        }
      }
    }
  }

  dynamic "deliver_artifact_collection" {
    for_each = each.value.stage_type == "DELIVER_ARTIFACT" && length(try(each.value.deliver_artifacts, [])) > 0 ? [each.value.deliver_artifacts] : []
    content {
      dynamic "items" {
        for_each = deliver_artifact_collection.value
        content {
          artifact_id   = items.value.artifact_id
          artifact_name = items.value.artifact_name
        }
      }
    }
  }

  dynamic "wait_criteria" {
    for_each = each.value.stage_type == "BUILD" && try(each.value.wait_duration, null) != null && try(each.value.wait_type, null) != null ? [1] : []
    content {
      wait_duration = each.value.wait_duration
      wait_type     = each.value.wait_type
    }
  }
}

resource "oci_devops_deploy_pipeline" "this" {
  for_each = var.deploy_pipelines

  project_id    = var.project_id
  display_name  = each.value.display_name
  description   = coalesce(each.value.description, each.value.display_name)
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  dynamic "deploy_pipeline_parameters" {
    for_each = length(each.value.parameters) == 0 ? [] : [each.value.parameters]
    content {
      dynamic "items" {
        for_each = deploy_pipeline_parameters.value
        content {
          name          = items.value.name
          default_value = items.value.default_value
          description   = try(items.value.description, null)
        }
      }
    }
  }
}

resource "oci_devops_deploy_stage" "root" {
  for_each = local.deploy_root_stage_map

  deploy_pipeline_id                       = oci_devops_deploy_pipeline.this[each.value.pipeline_key].id
  deploy_stage_type                        = each.value.stage_type
  display_name                             = each.value.display_name
  description                              = coalesce(each.value.description, each.value.display_name)
  oke_cluster_deploy_environment_id        = contains(["OKE_HELM_CHART_DEPLOYMENT", "OKE_DEPLOYMENT", "OKE_CANARY_DEPLOYMENT", "OKE_BLUE_GREEN_DEPLOYMENT"], each.value.stage_type) ? try(each.value.deploy_environment_id, null) : null
  namespace                                = each.value.stage_type == "OKE_DEPLOYMENT" ? try(each.value.namespace, null) : null
  kubernetes_manifest_deploy_artifact_ids  = contains(["OKE_DEPLOYMENT", "OKE_CANARY_DEPLOYMENT", "OKE_BLUE_GREEN_DEPLOYMENT"], each.value.stage_type) ? try(each.value.kubernetes_manifest_deploy_artifact_ids, null) : null
  helm_chart_deploy_artifact_id            = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.helm_chart_deploy_artifact_id, null) : null
  release_name                             = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.release_name, null) : null
  values_artifact_ids                      = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.values_artifact_ids, null) : null
  are_hooks_enabled                        = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.are_hooks_enabled, null) : null
  should_reuse_values                      = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.should_reuse_values, null) : null
  should_not_wait                          = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.should_not_wait, null) : null
  max_history                              = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.max_history, null) : null
  timeout_in_seconds                       = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.timeout_in_seconds, null) : null
  oke_canary_deploy_stage_id               = null
  oke_canary_traffic_shift_deploy_stage_id = null
  oke_blue_green_deploy_stage_id           = null
  purpose                                  = each.value.stage_type == "INVOKE_FUNCTION" ? try(each.value.purpose, null) : null
  deploy_artifact_id                       = each.value.stage_type == "INVOKE_FUNCTION" ? try(each.value.deploy_artifact_id, null) : null

  deploy_stage_predecessor_collection {
    items {
      id = oci_devops_deploy_pipeline.this[each.value.pipeline_key].id
    }
  }

  dynamic "canary_strategy" {
    for_each = each.value.stage_type == "OKE_CANARY_DEPLOYMENT" && try(each.value.canary_strategy, null) != null ? [each.value.canary_strategy] : []
    content {
      ingress_name  = canary_strategy.value.ingress_name
      namespace     = canary_strategy.value.namespace
      strategy_type = canary_strategy.value.strategy_type
    }
  }

  dynamic "rollout_policy" {
    for_each = each.value.stage_type == "OKE_CANARY_TRAFFIC_SHIFT" && try(each.value.rollout_policy, null) != null ? [each.value.rollout_policy] : []
    content {
      batch_count            = rollout_policy.value.batch_count
      batch_delay_in_seconds = rollout_policy.value.batch_delay_in_seconds
      batch_percentage       = rollout_policy.value.batch_percentage
      ramp_limit_percent     = rollout_policy.value.ramp_limit_percent
    }
  }

  dynamic "approval_policy" {
    for_each = contains(["OKE_CANARY_APPROVAL", "MANUAL_APPROVAL"], each.value.stage_type) && try(each.value.approval_policy, null) != null ? [each.value.approval_policy] : []
    content {
      approval_policy_type         = approval_policy.value.approval_policy_type
      number_of_approvals_required = approval_policy.value.number_of_approvals_required
    }
  }

  dynamic "rollback_policy" {
    for_each = each.value.stage_type == "OKE_DEPLOYMENT" && try(each.value.rollback_policy, null) != null ? [each.value.rollback_policy] : []
    content {
      policy_type = rollback_policy.value.policy_type
    }
  }

  dynamic "blue_green_strategy" {
    for_each = each.value.stage_type == "OKE_BLUE_GREEN_DEPLOYMENT" && try(each.value.blue_green_strategy, null) != null ? [each.value.blue_green_strategy] : []
    content {
      ingress_name  = blue_green_strategy.value.ingress_name
      namespace_a   = blue_green_strategy.value.namespace_a
      namespace_b   = blue_green_strategy.value.namespace_b
      strategy_type = blue_green_strategy.value.strategy_type
    }
  }
}

resource "oci_devops_deploy_stage" "dependent" {
  for_each = local.deploy_dependent_stage_map

  deploy_pipeline_id                       = oci_devops_deploy_pipeline.this[each.value.pipeline_key].id
  deploy_stage_type                        = each.value.stage_type
  display_name                             = each.value.display_name
  description                              = coalesce(each.value.description, each.value.display_name)
  oke_cluster_deploy_environment_id        = contains(["OKE_HELM_CHART_DEPLOYMENT", "OKE_DEPLOYMENT", "OKE_CANARY_DEPLOYMENT", "OKE_BLUE_GREEN_DEPLOYMENT"], each.value.stage_type) ? try(each.value.deploy_environment_id, null) : null
  namespace                                = each.value.stage_type == "OKE_DEPLOYMENT" ? try(each.value.namespace, null) : null
  kubernetes_manifest_deploy_artifact_ids  = contains(["OKE_DEPLOYMENT", "OKE_CANARY_DEPLOYMENT", "OKE_BLUE_GREEN_DEPLOYMENT"], each.value.stage_type) ? try(each.value.kubernetes_manifest_deploy_artifact_ids, null) : null
  helm_chart_deploy_artifact_id            = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.helm_chart_deploy_artifact_id, null) : null
  release_name                             = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.release_name, null) : null
  values_artifact_ids                      = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.values_artifact_ids, null) : null
  are_hooks_enabled                        = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.are_hooks_enabled, null) : null
  should_reuse_values                      = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.should_reuse_values, null) : null
  should_not_wait                          = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.should_not_wait, null) : null
  max_history                              = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.max_history, null) : null
  timeout_in_seconds                       = each.value.stage_type == "OKE_HELM_CHART_DEPLOYMENT" ? try(each.value.timeout_in_seconds, null) : null
  oke_canary_deploy_stage_id               = each.value.stage_type == "OKE_CANARY_TRAFFIC_SHIFT" ? coalesce(try(oci_devops_deploy_stage.root["${each.value.pipeline_key}:${each.value.oke_canary_deploy_stage_key}"].id, null), oci_devops_deploy_stage.dependent["${each.value.pipeline_key}:${each.value.oke_canary_deploy_stage_key}"].id) : null
  oke_canary_traffic_shift_deploy_stage_id = each.value.stage_type == "OKE_CANARY_APPROVAL" ? coalesce(try(oci_devops_deploy_stage.root["${each.value.pipeline_key}:${each.value.oke_canary_traffic_shift_stage_key}"].id, null), oci_devops_deploy_stage.dependent["${each.value.pipeline_key}:${each.value.oke_canary_traffic_shift_stage_key}"].id) : null
  oke_blue_green_deploy_stage_id           = each.value.stage_type == "OKE_BLUE_GREEN_TRAFFIC_SHIFT" ? coalesce(try(oci_devops_deploy_stage.root["${each.value.pipeline_key}:${each.value.oke_blue_green_deploy_stage_key}"].id, null), oci_devops_deploy_stage.dependent["${each.value.pipeline_key}:${each.value.oke_blue_green_deploy_stage_key}"].id) : null
  purpose                                  = each.value.stage_type == "INVOKE_FUNCTION" ? try(each.value.purpose, null) : null
  deploy_artifact_id                       = each.value.stage_type == "INVOKE_FUNCTION" ? try(each.value.deploy_artifact_id, null) : null

  deploy_stage_predecessor_collection {
    dynamic "items" {
      for_each = each.value.predecessor_keys
      content {
        id = coalesce(
          try(oci_devops_deploy_stage.root["${each.value.pipeline_key}:${items.value}"].id, null),
          oci_devops_deploy_stage.dependent["${each.value.pipeline_key}:${items.value}"].id
        )
      }
    }
  }

  dynamic "canary_strategy" {
    for_each = each.value.stage_type == "OKE_CANARY_DEPLOYMENT" && try(each.value.canary_strategy, null) != null ? [each.value.canary_strategy] : []
    content {
      ingress_name  = canary_strategy.value.ingress_name
      namespace     = canary_strategy.value.namespace
      strategy_type = canary_strategy.value.strategy_type
    }
  }

  dynamic "rollout_policy" {
    for_each = each.value.stage_type == "OKE_CANARY_TRAFFIC_SHIFT" && try(each.value.rollout_policy, null) != null ? [each.value.rollout_policy] : []
    content {
      batch_count            = rollout_policy.value.batch_count
      batch_delay_in_seconds = rollout_policy.value.batch_delay_in_seconds
      batch_percentage       = rollout_policy.value.batch_percentage
      ramp_limit_percent     = rollout_policy.value.ramp_limit_percent
    }
  }

  dynamic "approval_policy" {
    for_each = contains(["OKE_CANARY_APPROVAL", "MANUAL_APPROVAL"], each.value.stage_type) && try(each.value.approval_policy, null) != null ? [each.value.approval_policy] : []
    content {
      approval_policy_type         = approval_policy.value.approval_policy_type
      number_of_approvals_required = approval_policy.value.number_of_approvals_required
    }
  }

  dynamic "rollback_policy" {
    for_each = each.value.stage_type == "OKE_DEPLOYMENT" && try(each.value.rollback_policy, null) != null ? [each.value.rollback_policy] : []
    content {
      policy_type = rollback_policy.value.policy_type
    }
  }

  dynamic "blue_green_strategy" {
    for_each = each.value.stage_type == "OKE_BLUE_GREEN_DEPLOYMENT" && try(each.value.blue_green_strategy, null) != null ? [each.value.blue_green_strategy] : []
    content {
      ingress_name  = blue_green_strategy.value.ingress_name
      namespace_a   = blue_green_strategy.value.namespace_a
      namespace_b   = blue_green_strategy.value.namespace_b
      strategy_type = blue_green_strategy.value.strategy_type
    }
  }
}
