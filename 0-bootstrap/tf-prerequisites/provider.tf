# Applied by hand with your own admin credentials in the management account
# (aws sso login), not by CI.
provider "aws" {
  region              = local.lz_config.global.home_region
  allowed_account_ids = [local.lz_config.global.management_account_id]

  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "0-bootstrap/tf-prerequisites"
    })
  }
}
