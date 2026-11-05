terraform {
  backend "s3" {
    key = "1-org/aws-secure-baseline/s3-baseline/terraform.tfstate"
  }
}
