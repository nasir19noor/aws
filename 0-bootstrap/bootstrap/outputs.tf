output "organization_id" {
  value = aws_organizations_organization.org.id
}

output "root_id" {
  value = aws_organizations_organization.org.roots[0].id
}

output "management_account_id" {
  value = aws_organizations_organization.org.master_account_id
}

# GitHub repository variable AWS_ROLE_ARN.
output "role_arn" {
  value = aws_iam_role.github.arn
}
