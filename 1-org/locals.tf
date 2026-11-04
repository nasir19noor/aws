locals {
  lz_config     = yamldecode(file("${path.module}/../lzconfig.yaml"))
  org_structure = local.lz_config.org.org_hierarchy
  switch_role   = local.lz_config.global.switch_role_to_assume
  root_id       = data.aws_organizations_organization.org.roots[0].id

  # Variables the SCP templates in terraform/scp-stored use.
  scp_vars = {
    target_regions    = jsonencode(local.lz_config.org.common.target_regions)
    cloudtrail_bucket = local.lz_config.org.cloudtrail.bucket
    switch_role       = local.switch_role
  }
}
