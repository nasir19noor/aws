output "organization_id" {
  value = data.aws_organizations_organization.org.id
}

output "management_account_id" {
  value = data.aws_organizations_organization.org.master_account_id
}

output "root_id" {
  value = local.root_id
}

# OU IDs, by key in lzconfig.yaml (security, workloads, prod, ...).
output "ou_id_map" {
  value = merge(
    { for k, ou in module.main_ou : k => ou.detail.id },
    { for k, ou in module.sub_ou : k => ou.detail.id },
  )
}

# Account IDs, by key in lzconfig.yaml (log_archive_account, ...).
output "accounts_id_map" {
  value = { for k, a in module.account : k => a.id }
}

output "switch_role_to_assume" {
  value = local.switch_role
}
