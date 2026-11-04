# One OU and the SCPs attached to it.

resource "aws_organizations_organizational_unit" "this" {
  name      = var.ou_name
  parent_id = var.parent_id
}

resource "aws_organizations_policy_attachment" "this" {
  for_each  = toset(var.attached_policy)
  policy_id = var.policies[each.value]
  target_id = aws_organizations_organizational_unit.this.id
}
