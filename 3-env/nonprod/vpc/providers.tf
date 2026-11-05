# Runs in the environment's account (lzconfig env.nonprod.account), through
# OrganizationAccountAccessRole.
provider "aws" {
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map[local.env.account]}:role/${local.switch_role}"
  }

  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage       = "3-env/nonprod/vpc"
      environment = local.env.env
    })
  }
}
