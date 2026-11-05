# Organization trail: management events of every account and region, into the
# Log Archive bucket. The first copy of management events is free; data
# events, Insights, CloudWatch Logs delivery and KMS encryption (all paid) are
# off. Member accounts can't stop or change it (denyCloudtrailChanges SCP).

data "terraform_remote_state" "logging" {
  backend = "s3"
  config = {
    bucket = local.lz_config.global.lz_state_bucket
    key    = "1-org/logging-buckets/terraform.tfstate"
    region = local.region
  }
}

resource "aws_cloudtrail" "org" {
  name                          = local.lz_config.org.cloudtrail.name
  s3_bucket_name                = data.terraform_remote_state.logging.outputs.cloudtrail_bucket
  is_organization_trail         = true
  is_multi_region_trail         = local.lz_config.org.cloudtrail.multi_region_trail
  include_global_service_events = local.lz_config.org.cloudtrail.include_global_service_events
  enable_log_file_validation    = local.lz_config.org.cloudtrail.log_file_validation
}
