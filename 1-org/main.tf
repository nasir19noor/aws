# OUs, member accounts and SCPs, from org.org_hierarchy in lzconfig.yaml.
# SCPs are attached to OUs and accounts, never to Root: accounts left directly
# under Root are unaffected, and SCPs never restrict the management account.
# AWS's FullAWSAccess policy stays attached to Root.

locals {
  scp_names = distinct(flatten(concat(
    [for ou in local.org_structure : ou.scps],
    [for ou in local.org_structure : [for a in ou.accounts : a.scps]],
    [for ou in local.org_structure : [for sub in try(ou.sub_ous, {}) : sub.scps]],
    [for ou in local.org_structure : [for sub in try(ou.sub_ous, {}) : [for a in sub.accounts : a.scps]]],
  )))

  main_ou = { for k, ou in local.org_structure : k => ou }

  sub_ou = merge([
    for parent, ou in local.org_structure : { for k, sub in try(ou.sub_ous, {}) : k => merge(sub, { parent = parent }) }
  ]...)

  accounts = merge(
    merge([for k, ou in local.main_ou : { for a, acc in ou.accounts : a => merge(acc, { ou = k, level = "main" }) }]...),
    merge([for k, ou in local.sub_ou : { for a, acc in ou.accounts : a => merge(acc, { ou = k, level = "sub" }) }]...),
  )
}

resource "aws_organizations_policy" "policy" {
  for_each = toset(local.scp_names)
  name     = each.value
  type     = "SERVICE_CONTROL_POLICY"
  content  = templatefile("${path.module}/../terraform/scp-stored/${each.value}.json", local.scp_vars)
}

locals {
  policies = { for name, p in aws_organizations_policy.policy : name => p.id }
}

module "main_ou" {
  for_each        = local.main_ou
  source          = "../terraform/modules/organization-unit"
  ou_name         = each.value.name
  parent_id       = local.root_id
  policies        = local.policies
  attached_policy = each.value.scps
}

module "sub_ou" {
  for_each        = local.sub_ou
  source          = "../terraform/modules/organization-unit"
  ou_name         = each.value.name
  parent_id       = module.main_ou[each.value.parent].detail.id
  policies        = local.policies
  attached_policy = each.value.scps
}

module "account" {
  for_each        = local.accounts
  source          = "../terraform/modules/org-account"
  name            = each.value.name
  email           = each.value.email
  parent_id       = each.value.level == "main" ? module.main_ou[each.value.ou].detail.id : module.sub_ou[each.value.ou].detail.id
  role_name       = local.switch_role
  policies        = local.policies
  attached_policy = each.value.scps

  iam_user_access_to_billing = local.lz_config.org.account_defaults.iam_user_access_to_billing
  close_on_deletion          = local.lz_config.org.account_defaults.close_on_deletion
}
