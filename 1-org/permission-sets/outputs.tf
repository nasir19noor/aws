output "permission_sets" {
  value = { for k, p in aws_ssoadmin_permission_set.this : k => p.arn }
}

# e-mail, account ID, permission set: one line per assignment.
output "assignments" {
  value = sort([for a in local.assignments : "${a.email}  ${a.account}  ${a.pset}"])
}
