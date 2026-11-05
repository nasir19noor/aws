# Runs in the bucket's account (org.cloudtrail.bucket_account, Log Archive),
# through OrganizationAccountAccessRole (also exempt from the
# denyS3Modification SCP that protects the bucket).
provider "aws" {
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map[local.lz_config.org.cloudtrail.bucket_account]}:role/${local.switch_role}"
  }

  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/logging-buckets"
    })
  }
}
