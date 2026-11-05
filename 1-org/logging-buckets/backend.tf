terraform {
  backend "s3" {
    key = "1-org/logging-buckets/terraform.tfstate"
  }
}
