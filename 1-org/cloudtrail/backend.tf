terraform {
  backend "s3" {
    key = "1-org/cloudtrail/terraform.tfstate"
  }
}
