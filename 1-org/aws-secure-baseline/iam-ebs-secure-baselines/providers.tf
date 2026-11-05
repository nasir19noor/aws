# One provider per member account, as in the Ollion landing zone (Terraform
# can't loop providers). To cover a new account, add a provider here and a
# module in main.tf. The management account is left out on purpose: it
# runs existing workloads.

provider "aws" {
  alias  = "log_archive_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["log_archive_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}

provider "aws" {
  alias  = "security_tooling_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["security_tooling_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}

provider "aws" {
  alias  = "network_hub_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["network_hub_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}

provider "aws" {
  alias  = "shared_services_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["shared_services_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}

provider "aws" {
  alias  = "prod_master_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["prod_master_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}

provider "aws" {
  alias  = "nonprod_master_account"
  region = local.region
  assume_role {
    role_arn = "arn:aws:iam::${local.accounts_map["nonprod_master_account"]}:role/${local.switch_role}"
  }
  default_tags {
    tags = merge(local.lz_config.global.default_tags, {
      stage = "1-org/aws-secure-baseline/iam-ebs-secure-baselines"
    })
  }
}
