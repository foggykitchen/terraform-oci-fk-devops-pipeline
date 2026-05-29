output "build_pipeline_ids" {
  description = "Map of build pipeline OCIDs keyed by logical name."
  value       = { for key, pipeline in oci_devops_build_pipeline.this : key => pipeline.id }
}

output "build_stage_ids" {
  description = "Map of build stage OCIDs keyed by pipeline:stage."
  value       = { for key, stage in oci_devops_build_pipeline_stage.this : key => stage.id }
}

output "deploy_pipeline_ids" {
  description = "Map of deploy pipeline OCIDs keyed by logical name."
  value       = { for key, pipeline in oci_devops_deploy_pipeline.this : key => pipeline.id }
}

output "deploy_stage_ids" {
  description = "Map of deploy stage OCIDs keyed by pipeline:stage."
  value       = { for key, stage in oci_devops_deploy_stage.this : key => stage.id }
}
