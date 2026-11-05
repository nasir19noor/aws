terraform {
  backend "s3" {
    key = "1-org/aws-secure-baseline/access-analyzer/terraform.tfstate"
  }
}
