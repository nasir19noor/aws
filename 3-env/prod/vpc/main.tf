locals {
  env = local.lz_config.env["prod"]
}

module "vpc" {
  source = "../../../terraform/modules/env-vpc"
  name   = local.env.vpc_name
  cidr   = local.env.vpc_cidr
  region = local.region

  public_subnets          = local.env.public_subnets
  private_subnets         = local.env.private_subnets
  map_public_ip_on_launch = local.env.map_public_ip_on_launch
  gateway_endpoints       = local.env.gateway_endpoints
}
