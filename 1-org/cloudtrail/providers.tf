# An organization trail is created in the management account.
provider "aws" {
  region              = local.region
  allowed_account_ids = [local.lz_config.global.management_account_id]

  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/cloudtrail"
    })
  }
}
