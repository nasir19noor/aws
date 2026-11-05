variable "name" {
  description = "Account name"
  type        = string
}

variable "email" {
  description = "Root user e-mail; unique across AWS"
  type        = string
}

variable "parent_id" {
  description = "OU the account is placed in"
  type        = string
}

variable "role_name" {
  description = "Admin role Organizations creates in the account"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "policies" {
  description = "SCP IDs, by SCP name"
  type        = map(string)
}

variable "attached_policy" {
  description = "Names of the SCPs to attach to the account"
  type        = list(string)
  default     = []
}

variable "iam_user_access_to_billing" {
  description = "ALLOW or DENY: IAM users and roles with permission may see billing"
  type        = string
  default     = "ALLOW"
}

variable "close_on_deletion" {
  description = "Close the account when it is removed from Terraform"
  type        = bool
  default     = false
}
