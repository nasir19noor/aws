# The organization already exists (r-iyjk, management account 647459380434):
# it is imported, not created. Both lists below are authoritative, so they
# start from what is enabled today; nothing already enabled is turned off.

data "aws_organizations_organization" "current" {}

import {
  to = aws_organizations_organization.org
  id = data.aws_organizations_organization.current.id
}

locals {
  # Trusted access the landing zone needs (bootstrap.org in lzconfig.yaml).
  service_principals = local.lz_config.bootstrap.org.service_access_principals

  enabled_policy_types = [
    for p in data.aws_organizations_organization.current.roots[0].policy_types : p.type if p.status == "ENABLED"
  ]
}

resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  aws_service_access_principals = sort(setunion(
    data.aws_organizations_organization.current.aws_service_access_principals,
    local.service_principals,
  ))
  enabled_policy_types = sort(setunion(local.enabled_policy_types, ["SERVICE_CONTROL_POLICY"]))
}
