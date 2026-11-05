# IAM Identity Center: permission sets, the users from
# org.permission_sets_principal and their account assignments from org.access.
# Sign-in itself goes through Google Cloud Identity (SAML); see
# docs/identity-center-cloud-identity.md.

data "aws_ssoadmin_instances" "this" {}

locals {
  org          = local.lz_config.org
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  store_id     = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  # Job role -> list of e-mails (a value may be one e-mail or a list).
  role_emails = { for role, v in local.org.permission_sets_principal : role => flatten([v]) }
  emails      = toset(flatten(values(local.role_emails)))

  # Target -> account keys. Targets: an OU key (its accounts and its sub-OUs'
  # accounts), a sub-OU key, or an account key.
  h = local.org.org_hierarchy
  ou_accounts = merge(
    { for k, ou in local.h : k => concat(
      keys(ou.accounts),
      flatten([for sub in try(ou.sub_ous, {}) : keys(sub.accounts)]),
    ) },
    merge([for ou in local.h : { for k, sub in try(ou.sub_ous, {}) : k => keys(sub.accounts) }]...),
  )
  target_accounts = merge(
    local.ou_accounts,
    { for a in keys(local.accounts_map) : a => [a] },
  )
  account_id = merge(local.accounts_map, { management = local.mgmt_account })

  # One entry per (e-mail, account, permission set).
  assignments = merge([
    for role, targets in local.org.access : merge([
      for target, pset in targets : merge([
        for email in local.role_emails[role] : {
          for acct in(target == "management" ? ["management"] : local.target_accounts[target]) :
          "${email} ${acct} ${pset}" => { email = email, account = local.account_id[acct], pset = pset }
        }
      ]...)
    ]...)
  ]...)
}

# --- Permission sets -------------------------------------------------------------

# Permission sets made by hand (e.g. AdministratorAccess for the bootstrap) are
# imported, with their policy attachment, instead of created.
data "aws_ssoadmin_permission_set" "existing" {
  for_each     = toset(local.org.existing_permission_sets)
  instance_arn = local.instance_arn
  name         = each.value
}

import {
  for_each = data.aws_ssoadmin_permission_set.existing
  to       = aws_ssoadmin_permission_set.this[each.key]
  id       = "${each.value.arn},${local.instance_arn}"
}

import {
  for_each = data.aws_ssoadmin_permission_set.existing
  to       = aws_ssoadmin_managed_policy_attachment.this[each.key]
  id       = "${local.org.permission_sets[each.key].policy},${each.value.arn},${local.instance_arn}"
}

resource "aws_ssoadmin_permission_set" "this" {
  for_each         = local.org.permission_sets
  name             = each.key
  instance_arn     = local.instance_arn
  session_duration = each.value.session_duration
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each           = local.org.permission_sets
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.key].arn
  managed_policy_arn = each.value.policy
}

# --- Users ----------------------------------------------------------------------
# Cloud Identity Free can't provision users to AWS, so they are created here.
# The user name must equal the Google primary e-mail.

resource "aws_identitystore_user" "this" {
  for_each          = local.emails
  identity_store_id = local.store_id
  user_name         = each.value
  display_name      = each.value

  name {
    given_name  = split("@", each.value)[0]
    family_name = split("@", each.value)[1]
  }

  emails {
    value   = each.value
    primary = true
  }
}

# --- Account assignments --------------------------------------------------------

resource "aws_ssoadmin_account_assignment" "this" {
  for_each           = local.assignments
  instance_arn       = local.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.pset].arn
  principal_type     = "USER"
  principal_id       = aws_identitystore_user.this[each.value.email].user_id
  target_type        = "AWS_ACCOUNT"
  target_id          = each.value.account

  depends_on = [aws_ssoadmin_managed_policy_attachment.this]
}
