# One environment's VPC, free resources only: VPC, one public and one private
# subnet per AZ, internet gateway, route tables, gateway endpoints and a
# default security group with no rules. No NAT gateway: private subnets reach
# only the gateway endpoints. Flow logs off. VPC and subnets use the modules
# of nasir19noor/terraform, pinned to a commit.

locals {
  az_count = length(var.public_subnets)
}

module "vpc" {
  source = "git::https://github.com/nasir19noor/terraform.git//aws/modules/vpc?ref=664101e308a10cba234e276e2825690a067725b5"

  name                 = var.name
  cidr                 = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "public_subnets" {
  source = "git::https://github.com/nasir19noor/terraform.git//aws/modules/subnet?ref=664101e308a10cba234e276e2825690a067725b5"

  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  cidr_blocks             = var.public_subnets
  subnet_count            = local.az_count
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = { Name = "${var.name}-public", tier = "public" }
}

module "private_subnets" {
  source = "git::https://github.com/nasir19noor/terraform.git//aws/modules/subnet?ref=664101e308a10cba234e276e2825690a067725b5"

  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  cidr_blocks             = var.private_subnets
  subnet_count            = local.az_count
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-private", tier = "private" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = module.vpc.vpc_id
  tags   = { Name = "${var.name}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = module.vpc.vpc_id
  tags   = { Name = "${var.name}-public" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = local.az_count
  subnet_id      = module.public_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.public.id
}

# No default route: no internet access without NAT (which is paid).
resource "aws_route_table" "private" {
  vpc_id = module.vpc.vpc_id
  tags   = { Name = "${var.name}-private" }
}

resource "aws_route_table_association" "private" {
  count          = local.az_count
  subnet_id      = module.private_subnets.subnet_ids[count.index]
  route_table_id = aws_route_table.private.id
}

# Gateway endpoints are free (interface endpoints are not).
resource "aws_vpc_endpoint" "gateway" {
  for_each          = toset(var.gateway_endpoints)
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.${each.value}"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]
  tags              = { Name = "${var.name}-${each.value}" }
}

# The default security group allows nothing, so resources must use their own.
resource "aws_default_security_group" "this" {
  vpc_id = module.vpc.vpc_id
  tags   = { Name = "${var.name}-default-locked" }
}
