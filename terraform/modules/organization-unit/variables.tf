variable "ou_name" {
  description = "Name of the OU"
  type        = string
}

variable "parent_id" {
  description = "Root (r-...) or OU (ou-...) the OU is created in"
  type        = string
}

variable "policies" {
  description = "SCP IDs, by SCP name"
  type        = map(string)
}

variable "attached_policy" {
  description = "Names of the SCPs to attach to the OU"
  type        = list(string)
  default     = []
}
