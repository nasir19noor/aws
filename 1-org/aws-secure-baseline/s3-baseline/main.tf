module "log_archive_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.log_archive_account }
}

module "security_tooling_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.security_tooling_account }
}

module "network_hub_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.network_hub_account }
}

module "shared_services_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.shared_services_account }
}

module "prod_master_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.prod_master_account }
}

module "nonprod_master_account" {
  source    = "../../../terraform/modules/aws-secure-baseline/s3-baseline"
  providers = { aws = aws.nonprod_master_account }
}

