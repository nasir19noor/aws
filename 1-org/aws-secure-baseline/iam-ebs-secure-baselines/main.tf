module "log_archive_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.log_archive_account }
  password_policy = local.lz_config.org.password_policy
}

module "security_tooling_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.security_tooling_account }
  password_policy = local.lz_config.org.password_policy
}

module "network_hub_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.network_hub_account }
  password_policy = local.lz_config.org.password_policy
}

module "shared_services_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.shared_services_account }
  password_policy = local.lz_config.org.password_policy
}

module "prod_master_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.prod_master_account }
  password_policy = local.lz_config.org.password_policy
}

module "nonprod_master_account" {
  source          = "../../../terraform/modules/aws-secure-baseline/iam-ebs-secure-baselines"
  providers       = { aws = aws.nonprod_master_account }
  password_policy = local.lz_config.org.password_policy
}

