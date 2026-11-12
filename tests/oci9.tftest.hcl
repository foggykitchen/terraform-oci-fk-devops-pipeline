# Synthetic fixtures only. Every run is plan-only; no tenancy credentials are used.
mock_provider "oci" {
  mock_resource "oci_devops_build_pipeline" {
    defaults = { "compartment_id" = "MOCK_OCID_COMPARTMENT", "id" = "MOCK_OCID_PIPELINE", "lifecycle_details" = "mock-value", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "time_updated" = "mock-value" }
  }
  mock_resource "oci_devops_build_pipeline_stage" {
    defaults = { "compartment_id" = "MOCK_OCID_COMPARTMENT", "id" = "MOCK_OCID_STAGE", "lifecycle_details" = "mock-value", "project_id" = "MOCK_OCID_MOCK", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "time_updated" = "mock-value" }
  }
  mock_resource "oci_devops_deploy_pipeline" {
    defaults = { "compartment_id" = "MOCK_OCID_COMPARTMENT", "deploy_pipeline_artifacts" = [{ "items" = [{ "deploy_artifact_id" = "MOCK_OCID_MOCK", "deploy_pipeline_stages" = [], "display_name" = "compatibility" }] }], "deploy_pipeline_environments" = [{ "items" = [{ "deploy_environment_id" = "MOCK_OCID_MOCK", "deploy_pipeline_stages" = [], "display_name" = "compatibility" }] }], "id" = "MOCK_OCID_PIPELINE", "lifecycle_details" = "mock-value", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "time_updated" = "mock-value" }
  }
  mock_resource "oci_devops_deploy_stage" {
    defaults = { "compartment_id" = "MOCK_OCID_COMPARTMENT", "id" = "MOCK_OCID_STAGE", "lifecycle_details" = "mock-value", "project_id" = "MOCK_OCID_MOCK", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "time_updated" = "mock-value" }
  }
  mock_resource "oci_devops_trigger" {
    defaults = { "compartment_id" = "MOCK_OCID_COMPARTMENT", "id" = "MOCK_OCID_TRIGGER", "lifecycle_details" = "mock-value", "state" = "AVAILABLE", "system_tags" = {}, "time_created" = "mock-value", "time_updated" = "mock-value", "trigger_url" = "mock-value" }
  }
}
variables {
  project_id = "MOCK_OCID_MOCK"
}

run "oci9_plan" {
  command = plan
}
