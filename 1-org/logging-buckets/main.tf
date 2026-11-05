# Bucket for the organization CloudTrail (1-org/cloudtrail). Nothing is ever
# deleted from it automatically; its configuration is protected by the
# denyS3Modification SCP on Log Archive.

locals {
  bucket    = local.lz_config.org.cloudtrail.bucket
  org_id    = data.terraform_remote_state.org.outputs.organization_id
  trail_arn = "arn:aws:cloudtrail:${local.region}:${local.mgmt_account}:trail/${local.lz_config.org.cloudtrail.name}"
}

# Pinned to a commit of nasir19noor/terraform.
module "cloudtrail_bucket" {
  source = "git::https://github.com/nasir19noor/terraform.git//aws/modules/s3?ref=664101e308a10cba234e276e2825690a067725b5"

  bucket        = local.bucket
  versioning    = local.lz_config.org.cloudtrail.bucket_versioning
  force_destroy = false
}

resource "aws_s3_bucket_ownership_controls" "cloudtrail" {
  bucket = module.cloudtrail_bucket.s3_bucket_id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# SSE-S3: free, unlike SSE-KMS.
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = module.cloudtrail_bucket.s3_bucket_id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# CloudTrail may only write the organization trail's logs, and only over TLS.
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = module.cloudtrail_bucket.s3_bucket_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = module.cloudtrail_bucket.s3_bucket_arn
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource = [
          "${module.cloudtrail_bucket.s3_bucket_arn}/AWSLogs/${local.mgmt_account}/*",
          "${module.cloudtrail_bucket.s3_bucket_arn}/AWSLogs/${local.org_id}/*",
        ]
        Condition = { StringEquals = { "aws:SourceArn" = local.trail_arn } }
      },
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = [module.cloudtrail_bucket.s3_bucket_arn, "${module.cloudtrail_bucket.s3_bucket_arn}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
    ]
  })

  depends_on = [aws_s3_bucket_ownership_controls.cloudtrail]
}
