output "build_pipeline_ids" {
  description = "Map of build pipeline OCIDs keyed by logical name."
  value       = { for key, pipeline in oci_devops_build_pipeline.this : key => pipeline.id }
}

output "build_stage_ids" {
  description = "Map of build stage OCIDs keyed by pipeline:stage."
  value = merge(
    { for key, stage in oci_devops_build_pipeline_stage.root : key => stage.id },
    { for key, stage in oci_devops_build_pipeline_stage.dependent : key => stage.id }
  )
}

output "deploy_pipeline_ids" {
  description = "Map of deploy pipeline OCIDs keyed by logical name."
  value       = { for key, pipeline in oci_devops_deploy_pipeline.this : key => pipeline.id }
}

output "deploy_stage_ids" {
  description = "Map of deploy stage OCIDs keyed by pipeline:stage."
  value = merge(
    { for key, stage in oci_devops_deploy_stage.root : key => stage.id },
    { for key, stage in oci_devops_deploy_stage.dependent : key => stage.id },
    { for key, stage in oci_devops_deploy_stage.second_dependent : key => stage.id },
    { for key, stage in oci_devops_deploy_stage.third_dependent : key => stage.id }
  )
}

output "trigger_ids" {
  description = "Map of trigger OCIDs keyed by logical name."
  value       = { for key, trigger in oci_devops_trigger.this : key => trigger.id }
}

output "trigger_urls" {
  description = "Map of trigger URLs keyed by logical name."
  value       = { for key, trigger in oci_devops_trigger.this : key => trigger.trigger_url }
}
