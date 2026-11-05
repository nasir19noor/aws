output "cloudtrail_bucket" {
  value = module.cloudtrail_bucket.s3_bucket_id
}

output "cloudtrail_bucket_arn" {
  value = module.cloudtrail_bucket.s3_bucket_arn
}
