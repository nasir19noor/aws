# One member account and the SCPs attached to it. Creating an account is free.
# With close_on_deletion off, removing it from Terraform doesn't close it;
# close accounts by hand (move them to the Suspended OU first).

resource "aws_organizations_account" "this" {
  name                       = var.name
  email                      = var.email
  parent_id                  = var.parent_id
  role_name                  = var.role_name
  iam_user_access_to_billing = var.iam_user_access_to_billing
  close_on_deletion          = var.close_on_deletion

  lifecycle {
    # Only used at creation; AWS doesn't return them afterwards.
    ignore_changes = [role_name, iam_user_access_to_billing]
  }
}

resource "aws_organizations_policy_attachment" "this" {
  for_each  = toset(var.attached_policy)
  policy_id = var.policies[each.value]
  target_id = aws_organizations_account.this.id
}
