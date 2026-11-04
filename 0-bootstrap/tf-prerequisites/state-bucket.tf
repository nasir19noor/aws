# Terraform state for every stage. Locking uses S3 lock files (use_lockfile),
# so there is no DynamoDB table.

# Pinned to a commit of nasir19noor/terraform: a change there never reaches
# the state bucket until the ref here is bumped.
module "state_bucket" {
  source = "git::https://github.com/nasir19noor/terraform.git//aws/modules/s3?ref=664101e308a10cba234e276e2825690a067725b5"

  bucket        = local.lz_config.global.lz_state_bucket
  versioning    = true
  force_destroy = false
}

# SSE-S3 (AES256), set explicitly: free, unlike SSE-KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = module.state_bucket.s3_bucket_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "state_tls_only" {
  bucket = module.state_bucket.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [module.state_bucket.s3_bucket_arn, "${module.state_bucket.s3_bucket_arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

output "state_bucket" {
  value = module.state_bucket.s3_bucket_id
}
