# Management account: registers Security Tooling as delegated administrator.
provider "aws" {
  region              = local.region
  allowed_account_ids = [local.lz_config.global.management_account_id]
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/access-analyzer"
    })
  }
}

# The delegated administrator (org.access_analyzer.admin_account): owns the
# organization-wide analyzer.
provider "aws" {
  alias  = "security_tooling"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map[local.lz_config.org.access_analyzer.admin_account]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/access-analyzer"
    })
  }
}
