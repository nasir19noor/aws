variable "name" {
  description = "VPC name, e.g. vpc-prod"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR, a /16"
  type        = string
}

variable "region" {
  description = "Region; the subnets use its a, b and c AZs"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet CIDRs, one per AZ (a, b, c, ...)"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private subnet CIDRs, one per AZ; same length as public_subnets"
  type        = list(string)

  validation {
    condition     = length(var.private_subnets) == length(var.public_subnets)
    error_message = "public_subnets and private_subnets need the same number of entries (one of each per AZ)."
  }
}

variable "map_public_ip_on_launch" {
  description = "Give instances in public subnets a public IP automatically"
  type        = bool
  default     = false
}

variable "gateway_endpoints" {
  description = "Gateway endpoints (free): s3, dynamodb"
  type        = list(string)
  default     = []
}
