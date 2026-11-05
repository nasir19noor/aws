# IAM password policy (for the rare IAM user; people sign in through Identity
# Center) and EBS encryption by default with the AWS managed key. Both free.

resource "aws_iam_account_password_policy" "this" {
  minimum_password_length        = var.password_policy.minimum_length
  require_lowercase_characters   = var.password_policy.require_lowercase
  require_uppercase_characters   = var.password_policy.require_uppercase
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  allow_users_to_change_password = var.password_policy.allow_user_change
  hard_expiry                    = var.password_policy.hard_expiry
  max_password_age               = var.password_policy.maximum_age
  password_reuse_prevention      = var.password_policy.reuse_history
}

# Per region: the provider's region (the only one SCPs allow).
resource "aws_ebs_encryption_by_default" "this" {
  enabled = true
}
