variable "password_policy" {
  description = "org.password_policy from lzconfig.yaml"
  type = object({
    minimum_length    = number
    require_lowercase = bool
    require_uppercase = bool
    require_numbers   = bool
    require_symbols   = bool
    allow_user_change = bool
    hard_expiry       = bool
    maximum_age       = number
    reuse_history     = number
  })
}
